Attribute VB_Name = "modGmwoExport"
Option Explicit

'==============================================================================
' GMWO export - all seven modules merged into one, for hand-import.
'
' GENERATED FILE. Do not edit. Edit src\*.bas in the gmwo-vba-export repo and
' re-run build-single-module.ps1.
'
' Import this into a macro-enabled workbook built from that repo, then press
' Check this workbook on the Config sheet: it runs 60 self-tests and will say
' whether the import worked.
'
' Two mechanical changes from the seven-module source: cross-module qualifiers
' are dropped, since the module names no longer exist, and every module-level
' declaration is hoisted above the procedures, because VBA requires that.
' Comments still cite the original file and line, e.g. modConfig.bas:208.
'==============================================================================

'--- declarations from modConfig.bas -----------------------------------------

'==============================================================================
' modConfig - reads everything the export needs out of worksheet cells.
'
' Nothing else in the project knows a cell address: the Config sheet exposes
' named ranges (cfg_*) and the Selection sheet exposes tables (tbl*), so the
' layout can be rearranged without touching code.
'==============================================================================

Public Const SHEET_CONFIG As String = "Config"
Public Const SHEET_SELECTION As String = "Selection"
Public Const SHEET_DATA As String = "Data"
Public Const SHEET_LOG As String = "Log"

'--- Named-range access -------------------------------------------------------

' Value of a cfg_* named range as trimmed text ("" when blank).

'--- declarations from modJson.bas -------------------------------------------

'==============================================================================
' modJson - deliberately minimal JSON support.
'
' This workbook never needs a JSON object model. All *data* arrives as csv; the
' only JSON it touches is the operation envelope, from which it reads five
' scalar fields (Id, Status, DownloadUrl, Filename, FailureReason). So instead
' of taking a dependency on a JSON library, JsonScalar pulls "key": <scalar>
' out of a response with a regular expression, and JsonEscape makes cell values
' safe to concatenate into a request body.
'
' Consequence to be aware of: JsonScalar returns the FIRST match anywhere in the
' document, with no notion of nesting. See the comments at each call site in
' modExport, and the deliberate test in 
'==============================================================================


'--- declarations from modHttp.bas -------------------------------------------

'==============================================================================
' modHttp - authenticated HTTP against the GMWO API.
'
' Uses WinHttp late-bound, so there is no project reference to add and the same
' file works on 32- and 64-bit Office.
'==============================================================================

#If VBA7 Then
    Private Declare PtrSafe Sub SleepApi Lib "kernel32" Alias "Sleep" (ByVal dwMilliseconds As Long)
#Else
    Private Declare Sub SleepApi Lib "kernel32" Alias "Sleep" (ByVal dwMilliseconds As Long)
#End If

Private Const MAX_ATTEMPTS As Long = 4

Public Type HttpResult
    Status As Long              ' 0 means the request never reached the server
    Body As String
    ErrorText As String
    RetryAfter As Double        ' seconds, from the Retry-After header; 0 when absent
End Type

' GET/POST with the bearer token attached, retrying throttling and server errors.
'
' Three things are retried and nothing else: 429, any 5xx, and a request that never
' reached the server. Anything else - including every 4xx other than 429 - is the
' answer and comes straight back, because retrying it would only repeat a request the
' server has already rejected on its merits.

'--- declarations from modExport.bas -----------------------------------------

'==============================================================================
' modExport - the export flow itself.
'
'   POST /v1/operations/export        -> a queued operation
'   GET  /v1/operations/{id}/await    -> repeat until it stops being in progress
'   GET  {artifact DownloadUrl}       -> the generated csv
'
' This mirrors export/export.ipynb in the gmwo-api-examples repo, minus the
' /resources tree-walk that finds the newest release: the forecast path is a
' cell instead, which keeps JSON handling down to a handful of scalar reads.
'==============================================================================

Private Const MAX_WAIT_SECONDS As Long = 900     ' 15 minutes before giving up on an operation

'--- Request body -------------------------------------------------------------

' usedSeriesTable comes back True when the selection came from tblSeries rather than
' from the three lists. Only the wording of what the user is told depends on it - the
' request is the same either way - but the two are mutually exclusive and a client who
' has filled in both needs to be told which one they are actually getting.

'--- declarations from modImport.bas -----------------------------------------

'==============================================================================
' modImport - loads the downloaded csv into the Data sheet.
'
' Workbooks.Open is deliberately NOT used here. It applies the machine's locale
' when reading numbers, so the same file loads differently on a UK and a German
' install, and it has no reliable way to be told otherwise.
'
' The import is followed by NeutraliseFormulas. Excel's text import treats a field
' beginning "=", "+" or "@" as a formula, so csv content would otherwise arrive as
' live formulas rather than as data - see the comment on that procedure.
'==============================================================================

' hasHeaderRow says whether the first line of the file is column headings, and only
' decides how row 1 is presented - see the tidy-up at the end. The caller knows,
' because it chose the format that produced the file: FormatHasHeaderRow.
' It defaults to True, which is right for every format but Classic_h.

'--- declarations from modUi.bas ---------------------------------------------

'==============================================================================
' modUi - button entry points, progress reporting and the Log sheet.
'
' Excel is single threaded, so it is unresponsive while a request is in flight.
' The status bar is the trade-off taken here rather than asynchronous calls.
'==============================================================================

'--- Buttons ------------------------------------------------------------------
'
' Both buttons run the same shape: log a header, call a flow function that returns
' Boolean and fills a message ByRef, then report. That shape lives once in Finish
' and ReportUnexpected below, so the wording a client reads exists in one place.


'--- declarations from modSelfTest.bas ---------------------------------------

'==============================================================================
' modSelfTest - checks that run with no access token and no network.
'
' Between them they cover everything except the calls themselves: the request
' body built from the real sheet contents, and field extraction applied to real
' GMWO responses. Results go to the Log sheet.
'
' SelfTest_RunAllQuiet is the same checks with no dialogs, for build-workbook.ps1.
'==============================================================================

'--- Interactive entry points -------------------------------------------------



'=============================================================================
' modConfig.bas
'=============================================================================

Public Function CfgValue(ByVal rangeName As String) As String
    Dim target As Range
    Dim v As Variant

    Set target = NamedRange(rangeName)
    If target Is Nothing Then
        ' User-facing: a client cannot act on the named range being gone, so this
        ' says what to do rather than what broke.
        Err.Raise vbObjectError + 513, "CfgValue", _
            "This workbook is missing one of its settings cells, so it cannot run." & vbLf & vbLf & _
            "Please ask whoever sent you this file for a fresh copy. (Missing: " & rangeName & ")"
    End If

    v = target.Value
    If IsError(v) Then
        CfgValue = ""
    ElseIf IsEmpty(v) Then
        CfgValue = ""
    Else
        CfgValue = Trim$(CStr(v))
    End If
End Function

Public Sub SetCfgValue(ByVal rangeName As String, ByVal value As String)
    Dim target As Range
    Set target = NamedRange(rangeName)
    If Not target Is Nothing Then target.Value = value
End Sub

' TRUE/FALSE cells arrive either as a real Boolean or as the text a user typed.
Public Function CfgBool(ByVal rangeName As String) As Boolean
    Dim s As String
    s = LCase$(CfgValue(rangeName))
    CfgBool = (s = "true" Or s = "yes" Or s = "y" Or s = "1")
End Function

Public Function NamedRange(ByVal rangeName As String) As Range
    On Error Resume Next
    Set NamedRange = ThisWorkbook.Names(rangeName).RefersToRange
    On Error GoTo 0
End Function

'--- Derived configuration ----------------------------------------------------

Public Function CfgBaseUrl() As String
    Dim s As String
    s = CfgValue("cfg_BaseUrl")
    Do While Len(s) > 0 And Right$(s, 1) = "/"
        s = Left$(s, Len(s) - 1)
    Loop
    CfgBaseUrl = s
End Function

' Blank cfg_OutputFolder means "next to the workbook".
Public Function CfgOutputFolder() As String
    Dim s As String
    s = CfgValue("cfg_OutputFolder")
    If Len(s) = 0 Then s = ThisWorkbook.Path
    Do While Len(s) > 1 And Right$(s, 1) = "\"
        s = Left$(s, Len(s) - 1)
    Loop
    CfgOutputFolder = s
End Function

'--- Selection tables ---------------------------------------------------------

Public Function FindTable(ByVal tableName As String) As ListObject
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(SHEET_SELECTION)
    If Not ws Is Nothing Then Set FindTable = ws.ListObjects(tableName)
    On Error GoTo 0
End Function

' One column of a table, or Nothing when the table has no column of that name.
' ListObject.ListColumns raises rather than returning Nothing for a name that is not
' there, so the guarded lookup lives here instead of at each caller. Both callers
' treat a missing column as "no value", never as an error: a client may reasonably
' delete a column they are not using.
Private Function FindColumn(ByVal lo As ListObject, ByVal columnName As String) As ListColumn
    On Error Resume Next
    Set FindColumn = lo.ListColumns(columnName)
    On Error GoTo 0
End Function

' Non-blank values of one column of a table, in sheet order.
Public Function TableColumn(ByVal tableName As String, ByVal columnName As String) As Collection
    Dim values As Collection
    Dim lo As ListObject
    Dim lc As ListColumn
    Dim cell As Range
    Dim text As String

    Set values = New Collection
    Set TableColumn = values

    Set lo = FindTable(tableName)
    If lo Is Nothing Then Exit Function
    If lo.DataBodyRange Is Nothing Then Exit Function

    Set lc = FindColumn(lo, columnName)
    If lc Is Nothing Then Exit Function

    For Each cell In lc.DataBodyRange.Cells
        text = Trim$(CStr(cell.Text))
        If Len(text) > 0 Then values.Add text
    Next cell
End Function

' Transformation is chosen on the Selection sheet rather than the Config sheet,
' because more than one can be picked at a time. This is the first of them, used
' when a tblSeries row leaves its own Transformation cell blank.
Public Function DefaultTransformation() As String
    Dim transformations As Collection
    Set transformations = TableColumn("tblTransformations", "Transformation")
    If transformations.Count > 0 Then DefaultTransformation = CStr(transformations(1))
End Function

' One cell of one row of a table, falling back when the column or cell is empty.
Public Function RowValue(ByVal lo As ListObject, ByVal rowIndex As Long, _
                         ByVal columnName As String, ByVal fallback As String) As String
    Dim lc As ListColumn
    Dim text As String

    Set lc = FindColumn(lo, columnName)
    If lc Is Nothing Then
        RowValue = fallback
        Exit Function
    End If

    text = Trim$(CStr(lc.DataBodyRange.Cells(rowIndex, 1).Text))
    If Len(text) = 0 Then text = fallback
    RowValue = text
End Function

'--- Validation ---------------------------------------------------------------

' Returns "" when the workbook is ready to run, otherwise a message to show the user.
Public Function ValidateConfig() As String
    Dim problems As Collection
    Dim folder As String
    Dim i As Long
    Dim message As String

    Set problems = New Collection

    ' Every message names the box on the Config sheet by the label next to it, not
    ' by its cfg_ range name: the label is what the person reading this can see.
    If Len(CfgBaseUrl()) = 0 Then _
        problems.Add "The API base URL box is empty. It should say https://model.oxfordeconomics.com/api"
    If Len(CfgValue("cfg_AccessToken")) = 0 Then _
        problems.Add "The Access token box is empty. Paste your token into it."
    If Len(CfgValue("cfg_ForecastPath")) = 0 Then _
        problems.Add "The Forecast path box is empty. This is the full path to the data you want, " & _
                     "for example:  /oxford-economics/releases/Global Economic Model/Jul26_2 25yr"
    If Len(CfgValue("cfg_From")) = 0 Then _
        problems.Add "The From period box is empty. Put in a start period, for example 2025Q1."
    If Len(CfgValue("cfg_To")) = 0 Then _
        problems.Add "The To period box is empty. Put in an end period, for example 2030Q4."

    folder = CfgOutputFolder()
    If Len(folder) = 0 Then
        problems.Add "This workbook has not been saved anywhere yet, so there is no folder to put " & _
                     "your results in. Save it to your computer first."
    ElseIf Len(Dir$(folder, vbDirectory)) = 0 Then
        problems.Add "This folder does not exist:  " & folder & vbLf & _
                     "    Check the Output folder box, or clear it to save next to this workbook."
    End If

    If problems.Count = 0 Then Exit Function

    message = "Nothing has been sent yet. Please sort this out first:"
    For i = 1 To problems.Count
        message = message & vbLf & "  - " & problems(i)
    Next i
    ValidateConfig = message
End Function

'--- Misc ---------------------------------------------------------------------

' Filenames come from the API and include the forecast name, which can contain
' characters Windows will not accept in a path.
'
' This is also the only thing standing between a value in the API's response and a
' file written to the client's disk, so it is treated as untrusted input rather
' than as a tidy-up. Stripping the separators and the colon is what keeps the write
' inside the output folder: "..\..\evil.csv" and "C:\Windows\evil.csv" both come
' out as an ordinary name in the folder the user chose.
Public Function SafeFileName(ByVal fileName As String) As String
    Dim illegal As Variant
    Dim i As Long
    Dim s As String

    s = Trim$(fileName)
    illegal = Array("\", "/", ":", "*", "?", """", "<", ">", "|", vbCr, vbLf, vbTab)
    For i = LBound(illegal) To UBound(illegal)
        s = Replace$(s, CStr(illegal(i)), "_")
    Next i

    If Len(s) = 0 Then s = "gmwo-export.csv"

    ' The extension is forced, not trusted. An export artifact is always a csv - the
    ' API reports it as "text/csv" and modImport parses it as one - so a response
    ' naming anything else is either a mistake or an attempt to have this workbook
    ' put a differently-typed file on a client's machine. Appending rather than
    ' replacing keeps the original name visible in the log and in the folder.
    If Len(s) < 5 Or StrComp(Right$(s, 4), ".csv", vbTextCompare) <> 0 Then s = s & ".csv"

    SafeFileName = s
End Function

'=============================================================================
' modJson.bas
'=============================================================================

Private Function ScalarRegex(ByVal key As String) As Object
    Dim re As Object
    Set re = CreateObject("VBScript.RegExp")
    re.Global = False
    re.IgnoreCase = False
    ' "key" : "some \"string\"" | -1.2e3 | true | false | null
    re.Pattern = """" & key & """\s*:\s*(""(?:[^""\\]|\\.)*""|-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?|true|false|null)"
    Set ScalarRegex = re
End Function

' First value of "key" in the document, unescaped. "" when absent or null.
Public Function JsonScalar(ByVal json As String, ByVal key As String) As String
    Dim matches As Object

    Set matches = ScalarRegex(key).Execute(json)
    If matches.Count = 0 Then Exit Function

    JsonScalar = Unquote(matches(0).SubMatches(0))
End Function

Private Function Unquote(ByVal raw As String) As String
    Dim body As String
    Dim out As String
    Dim ch As String
    Dim i As Long

    If Len(raw) < 2 Or Left$(raw, 1) <> """" Then
        ' A bare literal: number, true/false, or null.
        If LCase$(raw) <> "null" Then Unquote = raw
        Exit Function
    End If

    body = Mid$(raw, 2, Len(raw) - 2)

    i = 1
    Do While i <= Len(body)
        ch = Mid$(body, i, 1)
        If ch = "\" And i < Len(body) Then
            i = i + 1
            ch = Mid$(body, i, 1)
            Select Case ch
                Case "n": out = out & vbLf
                Case "r": out = out & vbCr
                Case "t": out = out & vbTab
                Case "b": out = out & Chr$(8)
                Case "f": out = out & Chr$(12)
                Case "u"
                    out = out & ChrW$(CLng("&H" & Mid$(body, i + 1, 4)))
                    i = i + 4
                Case Else
                    ' \" \\ \/ and anything else stands for itself.
                    out = out & ch
            End Select
        Else
            out = out & ch
        End If
        i = i + 1
    Loop

    Unquote = out
End Function

' Makes a cell value safe to place inside a JSON string literal.
Public Function JsonEscape(ByVal value As String) As String
    Dim s As String

    s = Replace$(value, "\", "\\")      ' backslashes first, or the escapes below get doubled
    s = Replace$(s, """", "\""")
    s = Replace$(s, vbCrLf, "\n")
    s = Replace$(s, vbCr, "\n")
    s = Replace$(s, vbLf, "\n")
    s = Replace$(s, vbTab, "\t")

    JsonEscape = s
End Function

'=============================================================================
' modHttp.bas
'=============================================================================

Public Function HttpSend(ByVal method As String, ByVal url As String, _
                         Optional ByVal body As String = "") As HttpResult
    Dim res As HttpResult
    Dim attempt As Long
    Dim waitSeconds As Double
    Dim reason As String

    For attempt = 1 To MAX_ATTEMPTS
        Attempt_ method, url, body, res

        If res.Status = 429 Then
            ' Enqueuing an operation is rate limited more tightly than other
            ' calls - see "Throttling" in the API guide. Retry-After is honoured
            ' when the server sends one; this is the only case that has one.
            waitSeconds = res.RetryAfter
            If waitSeconds <= 0 Then waitSeconds = Backoff(attempt)
            reason = "HTTP 429 (throttled)"
        ElseIf res.Status >= 500 Then
            waitSeconds = Backoff(attempt)
            reason = "HTTP " & res.Status
        ElseIf res.Status = 0 Then
            waitSeconds = Backoff(attempt)
            reason = "Transport error (" & res.ErrorText & ")"
        Else
            HttpSend = res
            Exit Function
        End If

        LogLine reason & " on " & method & " " & url & " - waiting " & waitSeconds & _
                      "s, attempt " & attempt & " of " & MAX_ATTEMPTS

        If attempt < MAX_ATTEMPTS Then SleepResponsive waitSeconds
    Next attempt

    HttpSend = res
End Function

' Creates a request with the access token attached. This is the ONE place in the
' project that attaches the token to anything, so it is the one place to read when
' asking where the token can end up: the two callers below are the whole answer.
'
' receiveTimeoutMs is per caller because the two genuinely differ, and it MUST stay
' comfortably above 60s. /operations/{id}/await deliberately holds the connection
' open for up to a minute before replying, and WinHttp's 30s default would abort it:
' the symptom is an intermittent "operation timed out" that looks like an API fault
' but is purely local.
Private Function OpenRequest(ByVal method As String, ByVal url As String, _
                             ByVal receiveTimeoutMs As Long) As Object
    Dim http As Object

    Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
    http.SetTimeouts 0, 60000, 60000, receiveTimeoutMs      ' Resolve, Connect, Send, Receive - ms
    http.Open method, url, False
    http.SetRequestHeader "Authorization", "Bearer " & CfgValue("cfg_AccessToken")

    Set OpenRequest = http
End Function

Private Sub Attempt_(ByVal method As String, ByVal url As String, ByVal body As String, _
                     ByRef res As HttpResult)
    Dim http As Object

    res.Status = 0
    res.Body = vbNullString
    res.ErrorText = vbNullString
    res.RetryAfter = 0

    On Error GoTo Failed

    Set http = OpenRequest(method, url, 120000)
    http.SetRequestHeader "Accept", "application/json"

    If Len(body) > 0 Then
        http.SetRequestHeader "Content-Type", "application/json"
        http.Send body
    Else
        http.Send
    End If

    res.Status = http.Status
    res.Body = http.ResponseText
    res.RetryAfter = RetryAfterSeconds(http)
    Exit Sub

Failed:
    res.Status = 0
    res.ErrorText = Err.Description
End Sub

' Scheme + host + port of a url, lowercased, with the path removed. "" when the
' string is not an absolute http-style url.
'
' Public only so modSelfTest can pin its behaviour - the download guard below is a
' security check, and an untested security check is not worth much.
Public Function UrlOrigin(ByVal url As String) As String
    Dim s As String
    Dim afterScheme As Long
    Dim slash As Long

    s = Trim$(url)
    afterScheme = InStr(1, s, "://", vbTextCompare)
    If afterScheme = 0 Then Exit Function

    afterScheme = afterScheme + 3
    slash = InStr(afterScheme, s, "/")
    If slash = 0 Then
        UrlOrigin = LCase$(s)
    Else
        UrlOrigin = LCase$(Left$(s, slash - 1))
    End If
End Function

' Downloads an artifact to disk.
' Returns "" on success, or a message describing the failure.
Public Function HttpDownloadToFile(ByVal url As String, ByVal filePath As String) As String
    Dim http As Object
    Dim stream As Object
    Dim expected As String
    Dim actual As String

    ' This request carries the access token, and unlike every other call its url
    ' comes out of the API's own response rather than the Config sheet. So check it
    ' points back where we called, and refuse rather than send the token elsewhere.
    '
    ' Compared as a whole scheme+host+port string and NOT as a prefix, because
    ' "https://model.oxfordeconomics.com@evil.example/x" starts with the expected
    ' host while actually addressing evil.example. Exact equality also rejects a
    ' downgrade to plain http, since the scheme is part of what is compared.
    '
    ' The strictness costs one thing: an explicit ":443" would not match a base url
    ' without one. Nothing observed from this API does that, and a loud refusal is
    ' the right way to fail if it ever changes.
    expected = UrlOrigin(CfgBaseUrl())
    actual = UrlOrigin(url)

    If Len(expected) = 0 Or Len(actual) = 0 Or StrComp(expected, actual, vbTextCompare) <> 0 Then
        LogLine "REFUSED to download from '" & Left$(url, 300) & "' - expected the host in " & _
                      "cfg_BaseUrl (" & expected & "). The access token was not sent."
        If Len(actual) = 0 Then actual = "(not a recognisable web address)"
        HttpDownloadToFile = "Your file was ready, but Oxford Economics pointed somewhere " & _
                             "unexpected to download it from, so nothing was downloaded." & vbLf & vbLf & _
                             "This is a safety check. Your access token is only ever sent to " & _
                             expected & ", and it was not sent anywhere this time." & vbLf & vbLf & _
                             "Please tell your Oxford Economics contact." & vbLf & _
                             "(It pointed to: " & actual & ")"
        Exit Function
    End If

    On Error GoTo Failed

    ' Only now, past the origin check above, is the token attached. Generous receive
    ' timeout: a wide selection can take a while to stream.
    Set http = OpenRequest("GET", url, 300000)
    http.Send

    If http.Status <> 200 Then
        HttpDownloadToFile = "Downloading the csv failed with HTTP " & http.Status & ". " & _
                             Left$(Trim$(http.ResponseText), 500)
        Exit Function
    End If

    ' URLDownloadToFile cannot attach an Authorization header, so the response
    ' body is streamed to disk instead of being held in a VBA string.
    Set stream = CreateObject("ADODB.Stream")
    stream.Type = 1                              ' adTypeBinary
    stream.Open
    stream.Write http.ResponseBody
    stream.SaveToFile filePath, 2                ' adSaveCreateOverWrite
    stream.Close
    Exit Function

Failed:
    HttpDownloadToFile = "Downloading the csv failed: " & Err.Description
    On Error Resume Next
    If Not stream Is Nothing Then If stream.State <> 0 Then stream.Close
End Function

Private Function RetryAfterSeconds(ByVal http As Object) As Double
    Dim header As String

    On Error Resume Next
    header = http.GetResponseHeader("Retry-After")     ' raises when the header is absent
    On Error GoTo 0

    ' Only the delta-seconds form is handled; an HTTP-date falls back to backoff.
    If IsNumeric(header) Then RetryAfterSeconds = CDbl(header)
End Function

Private Function Backoff(ByVal attempt As Long) As Double
    Backoff = 2 ^ attempt
End Function

' Waits without freezing Excel harder than it already is.
Public Sub SleepResponsive(ByVal seconds As Double)
    Dim slices As Long
    Dim i As Long

    slices = CLng(seconds * 10)
    For i = 1 To slices
        SleepApi 100
        DoEvents
    Next i
End Sub

'=============================================================================
' modExport.bas
'=============================================================================

Public Function BuildRequestBody(ByRef seriesCount As Long, ByRef usedSeriesTable As Boolean) As String
    Dim s As String
    Dim formatName As String

    s = "{""InputForecast"":""" & JsonEscape(CfgValue("cfg_ForecastPath")) & """"

    s = s & ",""Range"":{""From"":""" & JsonEscape(CfgValue("cfg_From")) & _
            """,""To"":""" & JsonEscape(CfgValue("cfg_To")) & """}"

    s = s & ",""SeriesSelection"":" & BuildSeriesSelection(seriesCount, usedSeriesTable)

    ' Format and AnnualRollup are optional; send them only when they differ from
    ' the API defaults, as the notebook's commented-out properties describe.
    formatName = CfgValue("cfg_Format")
    If Len(formatName) > 0 And StrComp(formatName, "Default", vbTextCompare) <> 0 Then
        s = s & ",""Format"":""" & JsonEscape(formatName) & """"
    End If

    If CfgBool("cfg_AnnualRollup") Then s = s & ",""AnnualRollup"":true"

    s = s & ",""OperationName"":""" & JsonEscape(OperationName()) & """"

    BuildRequestBody = s & "}"
End Function

' Whether the csv a format produces starts with a row of column headings.
'
' Six of the seven do. Classic_h is the Model software's Vars By Row layout, where
' the first line is already a series, so modImport must not bold and freeze it -
' that labels data as a heading. Public so the self-test can pin the mapping.
'
' Anything unrecognised is treated as having headings: a client can type into the
' Output format box, and the API may grow formats this workbook has never heard of.
' Being wrong that way leaves a bold first row, which is the milder mistake.
Public Function FormatHasHeaderRow(ByVal formatName As String) As Boolean
    FormatHasHeaderRow = (StrComp(Trim$(formatName), "Classic_h", vbTextCompare) <> 0)
End Function

' Labels the operation so this workbook's runs are identifiable in the operation
' history, rather than appearing as one unnamed job among others. Carries a
' timestamp, so BuildRequestBody is deliberately not byte-for-byte repeatable -
' don't write a test that pins the whole body.
Private Function OperationName() As String
    OperationName = ThisWorkbook.Name & " " & Format$(Now, "yyyy-mm-dd hh:nn:ss")
End Function

' tblSeries wins when it has rows, so a user can give individual series their own
' transformation; otherwise indicators x locations, as in the notebook.
'
' The two are alternatives, never a sum, and this is the only place that decides
' between them. usedSeriesTable reports which way it went, so that what a client is
' told matches what was actually sent - "rows" means rows FromSeriesTable could use,
' i.e. with both an Indicator and a Location, which is why the flag is set from
' seriesCount rather than from the table having body cells in it.
Public Function BuildSeriesSelection(ByRef seriesCount As Long, ByRef usedSeriesTable As Boolean) As String
    Dim explicitTable As ListObject

    seriesCount = 0
    usedSeriesTable = False

    Set explicitTable = FindTable("tblSeries")
    If Not explicitTable Is Nothing Then
        If Not explicitTable.DataBodyRange Is Nothing Then
            BuildSeriesSelection = FromSeriesTable(explicitTable, seriesCount)
            If seriesCount > 0 Then
                usedSeriesTable = True
                Exit Function
            End If
        End If
    End If

    BuildSeriesSelection = FromCrossProduct(seriesCount)
End Function

' Indicators x locations x transformations. Transformations are a list rather
' than a single setting, so one export can carry several of them: the API takes
' Transformation per item of SeriesSelection, and the same indicator+location may
' legitimately appear more than once with different transformations.
Private Function FromCrossProduct(ByRef seriesCount As Long) As String
    Dim indicators As Collection
    Dim locations As Collection
    Dim transformations As Collection
    Dim parts() As String
    Dim valueType As String
    Dim i As Long, j As Long, k As Long, n As Long

    Set indicators = TableColumn("tblIndicators", "Indicator")
    Set locations = TableColumn("tblLocations", "Location")
    Set transformations = TableColumn("tblTransformations", "Transformation")
    valueType = CfgValue("cfg_ValueType")

    seriesCount = indicators.Count * locations.Count * transformations.Count
    If seriesCount = 0 Then
        FromCrossProduct = "[]"
        Exit Function
    End If

    ' Collected into an array and joined once. Repeated "s = s & ..." is
    ' quadratic in VBA and gets slow around a few thousand series.
    ReDim parts(1 To seriesCount)
    For i = 1 To indicators.Count
        For j = 1 To locations.Count
            For k = 1 To transformations.Count
                n = n + 1
                parts(n) = SeriesJson(CStr(indicators(i)), CStr(locations(j)), _
                                      CStr(transformations(k)), valueType)
            Next k
        Next j
    Next i

    FromCrossProduct = "[" & Join(parts, ",") & "]"
End Function

Private Function FromSeriesTable(ByVal lo As ListObject, ByRef seriesCount As Long) As String
    Dim parts() As String
    Dim rowCount As Long, r As Long, n As Long
    Dim indicator As String, location As String
    Dim fallbackTransformation As String, fallbackValueType As String

    fallbackTransformation = DefaultTransformation()
    fallbackValueType = CfgValue("cfg_ValueType")

    rowCount = lo.DataBodyRange.Rows.Count
    ReDim parts(1 To rowCount)

    For r = 1 To rowCount
        indicator = RowValue(lo, r, "Indicator", "")
        location = RowValue(lo, r, "Location", "")
        If Len(indicator) > 0 And Len(location) > 0 Then
            n = n + 1
            parts(n) = SeriesJson(indicator, location, _
                                  RowValue(lo, r, "Transformation", fallbackTransformation), _
                                  RowValue(lo, r, "ValueType", fallbackValueType))
        End If
    Next r

    seriesCount = n
    If n = 0 Then
        FromSeriesTable = "[]"
        Exit Function
    End If

    ReDim Preserve parts(1 To n)
    FromSeriesTable = "[" & Join(parts, ",") & "]"
End Function

Private Function SeriesJson(ByVal indicator As String, ByVal location As String, _
                            ByVal transformation As String, ByVal valueType As String) As String
    Dim s As String

    s = "{""Indicator"":""" & JsonEscape(indicator) & _
        """,""Location"":""" & JsonEscape(location) & """"

    If Len(transformation) > 0 Then
        s = s & ",""Transformation"":""" & JsonEscape(transformation) & """"
    End If

    ' ValueType defaults to Variable server-side.
    If Len(valueType) > 0 And StrComp(valueType, "Variable", vbTextCompare) <> 0 Then
        s = s & ",""ValueType"":""" & JsonEscape(valueType) & """"
    End If

    SeriesJson = s & "}"
End Function

'--- The flow -----------------------------------------------------------------

Public Function RunExportFlow(ByRef resultMessage As String) As Boolean
    Dim problem As String
    Dim body As String
    Dim seriesCount As Long
    Dim usedSeriesTable As Boolean       ' which of the two selection blocks was used
    Dim res As HttpResult
    Dim operationId As String
    Dim operationStatus As String
    Dim downloadUrl As String
    Dim fileName As String
    Dim filePath As String
    Dim downloadError As String
    Dim startedAt As Date
    Dim checks As Long

    problem = ValidateConfig()
    If Len(problem) > 0 Then
        resultMessage = problem
        Exit Function
    End If

    body = BuildRequestBody(seriesCount, usedSeriesTable)
    If seriesCount = 0 Then
        resultMessage = "There is nothing to export yet." & vbLf & vbLf & _
                        "On the " & SHEET_SELECTION & " sheet, you need at least one indicator, " & _
                        "one location and one transformation."
        Exit Function
    End If

    ' Which block the series came from goes in the log rather than in the dialog: it
    ' is the first thing to check when a client says they exported the wrong things.
    LogLine "Exporting " & seriesCount & " series from " & CfgValue("cfg_ForecastPath") & _
                  " (" & CfgValue("cfg_From") & " to " & CfgValue("cfg_To") & _
                  ", " & IIf(usedSeriesTable, "exact combinations table", "three lists") & ")"

    '-- Trigger --------------------------------------------------------------
    Status "Submitting the export request..."
    res = HttpSend("POST", CfgBaseUrl() & "/v1/operations/export", body)

    If res.Status < 200 Or res.Status > 299 Then
        resultMessage = Describe("The export request", res)
        Exit Function
    End If

    ' On the POST response Artifacts and Resources are both empty, so the first
    ' "Id" in the payload is the operation id. Capture it HERE and nowhere else:
    ' JsonScalar has no notion of nesting, and on an await response the first
    ' "Id" belongs to Artifacts[0].
    operationId = JsonScalar(res.Body, "Id")
    operationStatus = JsonScalar(res.Body, "Status")

    If Len(operationId) = 0 Then
        resultMessage = "Oxford Economics accepted the request but did not say which job it created, " & _
                        "so this workbook cannot follow it." & vbLf & vbLf & _
                        "Please try again. If it keeps happening, send the " & SHEET_LOG & _
                        " sheet to your Oxford Economics contact."
        LogLine "Unrecognised export response: " & Left$(res.Body, 4000)
        Exit Function
    End If

    LogLine "Operation " & operationId & " queued"

    '-- Wait -----------------------------------------------------------------
    ' /await answers as soon as the operation finishes, or after about a minute,
    ' whichever comes first - so this loop normally runs once or twice.
    startedAt = Now
    Do While StrComp(operationStatus, "Queued", vbTextCompare) = 0 Or StrComp(operationStatus, "InProgress", vbTextCompare) = 0
        If DateDiff("s", startedAt, Now) > MAX_WAIT_SECONDS Then
            resultMessage = "This is taking longer than " & (MAX_WAIT_SECONDS \ 60) & " minutes, so the " & _
                            "workbook has stopped waiting." & vbLf & vbLf & _
                            "Your export may still finish at Oxford Economics' end - nothing has been " & _
                            "broken. Try again with fewer indicators or a shorter date range." & vbLf & _
                            "(Job " & operationId & ", still " & operationStatus & ".)"
            Exit Function
        End If

        checks = checks + 1
        Status "Waiting for the export to finish - check " & checks & ", " & _
                     DateDiff("s", startedAt, Now) & "s elapsed"

        res = HttpSend("GET", CfgBaseUrl() & "/v1/operations/" & operationId & "/await")
        If res.Status < 200 Or res.Status > 299 Then
            resultMessage = Describe("Waiting for operation " & operationId, res)
            Exit Function
        End If

        operationStatus = JsonScalar(res.Body, "Status")
    Loop

    If StrComp(operationStatus, "Succeeded", vbTextCompare) <> 0 Then
        resultMessage = "The export did not complete." & vbLf & vbLf & _
                        "Oxford Economics reported it as '" & operationStatus & "'."
        If Len(JsonScalar(res.Body, "FailureReason")) > 0 Then
            resultMessage = resultMessage & vbLf & vbLf & "Reason given: " & _
                            JsonScalar(res.Body, "FailureReason")
        End If
        resultMessage = resultMessage & vbLf & vbLf & _
                        "Check your indicator and location codes on the " & SHEET_SELECTION & " sheet."
        LogLine "Operation " & operationId & " ended as " & operationStatus & ": " & Left$(res.Body, 4000)
        Exit Function
    End If

    '-- Download -------------------------------------------------------------
    ' An export produces exactly one artifact, so the first DownloadUrl and
    ' Filename in the response belong to the generated csv.
    downloadUrl = JsonScalar(res.Body, "DownloadUrl")
    fileName = JsonScalar(res.Body, "Filename")

    If Len(downloadUrl) = 0 Then
        resultMessage = "The export finished, but Oxford Economics did not send back a file." & vbLf & vbLf & _
                        "Please try again. If it keeps happening, send the " & SHEET_LOG & _
                        " sheet to your Oxford Economics contact. (Job " & operationId & ".)"
        LogLine "No artifact in: " & Left$(res.Body, 4000)
        Exit Function
    End If

    If Len(fileName) = 0 Then fileName = "gmwo-export-" & Format$(Now, "yyyymmdd-hhnnss") & ".csv"
    filePath = CfgOutputFolder() & "\" & SafeFileName(fileName)

    Status "Downloading " & fileName & "..."
    downloadError = HttpDownloadToFile(downloadUrl, filePath)
    If Len(downloadError) > 0 Then
        resultMessage = downloadError
        Exit Function
    End If
    LogLine "Saved " & filePath

    '-- Load -----------------------------------------------------------------
    Status "Loading the csv into the " & SHEET_DATA & " sheet..."
    ImportCsv filePath, FormatHasHeaderRow(CfgValue("cfg_Format"))

    resultMessage = "Done - " & seriesCount & " series exported." & vbLf & vbLf & _
                    "Your numbers are on the " & SHEET_DATA & " sheet." & vbLf & vbLf & _
                    "A copy has also been saved as a spreadsheet file here:" & vbLf & filePath
    RunExportFlow = True
End Function

'--- Token check --------------------------------------------------------------

' GET /v1/users/me - the cheapest authenticated call the API has, so it answers
' "is this token any good?" without enqueuing anything.
'
' Nothing is read out of the body on purpose. The response is a PersonUser: the
' user's own Id/Code/Name plus a nested Organization carrying an Id/Code/Name of
' its own. JsonScalar is flat, and this API serialises nested objects *before*
' the properties of the type that contains them - the same quirk pinned in
' modSelfTest for the operation Id - so "Name" would most likely return the
' organisation, not the person. The status code is the answer; the body goes to
' the Log sheet for anyone who wants to read it.
Public Function CheckToken(ByRef resultMessage As String) As Boolean
    Dim res As HttpResult

    If Len(CfgValue("cfg_AccessToken")) = 0 Then
        resultMessage = "There is no token to check." & vbLf & vbLf & _
                        "Paste your access token into the Access token box on the " & _
                        SHEET_CONFIG & " sheet first."
        Exit Function
    End If

    If Len(CfgBaseUrl()) = 0 Then
        resultMessage = "The API base URL box on the " & SHEET_CONFIG & " sheet is empty." & vbLf & vbLf & _
                        "It should say https://model.oxfordeconomics.com/api"
        Exit Function
    End If

    Status "Checking the access token..."
    res = HttpSend("GET", CfgBaseUrl() & "/v1/users/me")
    LogLine "Token check: HTTP " & res.Status & " " & Left$(res.Body, 4000)

    If res.Status >= 200 And res.Status <= 299 Then
        resultMessage = "Your token works." & vbLf & vbLf & _
                        "Oxford Economics accepted it. You are ready to run an export." & vbLf & vbLf & _
                        "(Your account details came back too, and are on the " & SHEET_LOG & " sheet.)"
        CheckToken = True
        Exit Function
    End If

    resultMessage = Describe("The token check", res, suggestTokenCheck:=False)
End Function

' suggestTokenCheck is off when the token check is itself what failed - see the call in
' CheckToken. Everywhere else it is the right thing to advise.
Private Function Describe(ByVal what As String, ByRef res As HttpResult, _
                          Optional ByVal suggestTokenCheck As Boolean = True) As String
    If res.Status = 0 Then
        Describe = what & " could not reach Oxford Economics." & vbLf & vbLf & _
                   "Check that you are connected to the internet. If you are on a company network " & _
                   "or VPN, it may be blocking the connection." & vbLf & vbLf & _
                   "Technical detail: " & res.ErrorText
        Exit Function
    End If

    Select Case res.Status
        Case 401, 403
            ' Not "expired": GMWO tokens have no expiry, so a token that used to
            ' work has been revoked or altered, and saying otherwise sends people
            ' looking for the one cause that cannot happen.
            Describe = "Oxford Economics did not accept your access token." & vbLf & vbLf & _
                       "Check the Access token box on the " & SHEET_CONFIG & " sheet. It may be " & _
                       "missing, or only partly pasted in, or it may have been switched off." & vbLf & vbLf & _
                       "Tokens do not run out on their own, so one that worked before has not simply " & _
                       "gone out of date."

            ' Withheld when Test token is what produced this message: it would be
            ' telling the client to press the button they have just pressed.
            If suggestTokenCheck Then _
                Describe = Describe & vbLf & vbLf & "Press Test token to check the token by itself."
        Case 404
            Describe = "Oxford Economics could not find the data you asked for." & vbLf & vbLf & _
                       "Check the Forecast path box on the " & SHEET_CONFIG & " sheet."
        Case 429
            Describe = "Oxford Economics is asking you to slow down." & vbLf & vbLf & _
                       "Wait a minute, then try again."
        Case Else
            Describe = what & " did not work." & vbLf & vbLf & _
                       "Oxford Economics replied with error code " & res.Status & "."
    End Select

    ' Kept, but pushed to the bottom and labelled: it is the only clue when the
    ' cause is something this workbook has no specific message for, and modUi
    ' copies the whole message onto the Log sheet.
    If Len(Trim$(res.Body)) > 0 Then _
        Describe = Describe & vbLf & vbLf & "Technical detail (error code " & res.Status & "): " & _
                   Left$(Trim$(res.Body), 300)
End Function

'=============================================================================
' modImport.bas
'=============================================================================

Public Sub ImportCsv(ByVal filePath As String, Optional ByVal hasHeaderRow As Boolean = True)
    Dim ws As Worksheet
    Dim qt As QueryTable

    Set ws = ThisWorkbook.Worksheets(SHEET_DATA)

    ClearSheet ws

    Set qt = ws.QueryTables.Add(Connection:="TEXT;" & filePath, Destination:=ws.Range("A1"))
    With qt
        .TextFileParseType = xlDelimited
        .TextFileCommaDelimiter = True
        .TextFileTabDelimiter = False
        .TextFileSemicolonDelimiter = False
        .TextFileSpaceDelimiter = False
        .TextFileConsecutiveDelimiter = False
        ' TextFileOtherDelimiter is deliberately left alone: it wants a single
        ' character and raises 1004 if handed an empty string.

        ' Several columns - Source, Source details - contain commas inside quoted
        ' fields, so the text qualifier matters as much as the delimiter.
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .TextFilePlatform = 65001                       ' UTF-8

        ' Set these explicitly. Left alone, Excel uses the machine's regional
        ' settings and a German or French install reads 108.4667 as 1084667.
        .TextFileDecimalSeparator = "."
        .TextFileThousandsSeparator = ","

        .AdjustColumnWidth = True
        .RefreshStyle = xlOverwriteCells
        .SaveData = True

        .Refresh BackgroundQuery:=False

        ' The values stay behind; only the live connection goes. Without this the
        ' workbook keeps a query pointing at a file that may not exist next time.
        .Delete
    End With

    NeutraliseFormulas ws

    ' Default is one row per series and roughly 30 columns wide, so bolding and
    ' freezing its headings earns its keep. Classic_h has no headings at all - its
    ' first line is already a series - and doing this there dresses a row of data up
    ' as a heading. ClearSheet has just cleared the formatting, so an earlier run's
    ' bold row does not survive into a format that should not have one.
    If hasHeaderRow Then ws.Rows(1).Font.Bold = True

    Application.Goto ws.Range("A1"), True      ' activates the sheet too
    On Error Resume Next
    ' Unfrozen either way: a previous run's frozen pane would otherwise sit across
    ' the first row of data.
    ActiveWindow.FreezePanes = False
    If hasHeaderRow Then
        ws.Range("A2").Select
        ActiveWindow.FreezePanes = True
    End If
    ws.Range("A1").Select
    On Error GoTo 0
End Sub

' Turns every formula on the sheet back into the text it was imported from.
'
' The import above is Excel's own text import, and it parses a field beginning
' "=", "+", "-" or "@" as a formula rather than storing it as text. That makes the
' contents of the downloaded csv executable: "=HYPERLINK(""http://host/?""&A2,..)"
' becomes a link that sends a cell of this workbook to whoever is asked to fetch
' it, and "=cmd|'/c ..'!A1" is a DDE request. Current Excel blocks DDE by default,
' but neither should be reaching a client's machine in the first place.
'
' modHttp already declines to trust the download *url* the API returns. This is the
' same judgement applied to the response body.
'
' Nothing legitimate is lost: forecast data is numbers, dates and names, and none
' of those arrive as formulas. Setting the cell to Text format first is what makes
' the assignment inert - assigning "=1+1" to a General cell creates the formula
' again.
Private Sub NeutraliseFormulas(ByVal ws As Worksheet)
    Dim suspect As Range
    Dim cell As Range
    Dim imported As String

    ' SpecialCells raises 1004 when there are no formulas, which is the normal case.
    On Error Resume Next
    Set suspect = ws.UsedRange.SpecialCells(xlCellTypeFormulas)
    On Error GoTo 0
    If suspect Is Nothing Then Exit Sub

    For Each cell In suspect.Cells
        imported = cell.Formula
        cell.NumberFormat = "@"
        cell.Value = imported
        LogLine "Kept as text rather than as a formula: " & SHEET_DATA & "!" & _
                      cell.Address(False, False) & " = " & Left$(imported, 200)
    Next cell
End Sub

' Public so the Clear data sheet button goes through the same code an import does -
' see ClearData.
Public Sub ClearSheet(ByVal ws As Worksheet)
    ' Query tables and list objects both hold connections from previous runs.
    Do While ws.QueryTables.Count > 0
        ws.QueryTables(1).Delete
    Loop

    Do While ws.ListObjects.Count > 0
        ws.ListObjects(1).Unlist
    Loop

    ws.Cells.Clear
End Sub

'=============================================================================
' modUi.bas
'=============================================================================

Public Sub RunExport()
    Dim ok As Boolean
    Dim message As String

    On Error GoTo Unexpected

    LogLine "=== Export started ==="
    Status "Starting..."

    ok = RunExportFlow(message)
    Finish ok, message
    Exit Sub

Unexpected:
    ReportUnexpected Err.Number, Err.Description
End Sub

Public Sub TestToken()
    Dim ok As Boolean
    Dim message As String

    On Error GoTo Unexpected

    LogLine "=== Token check started ==="

    ok = CheckToken(message)
    Finish ok, message
    Exit Sub

Unexpected:
    ReportUnexpected Err.Number, Err.Description
End Sub

Private Sub Finish(ByVal ok As Boolean, ByVal message As String)
    ClearStatus
    LogLine IIf(ok, "SUCCESS. ", "STOPPED. ") & Replace$(message, vbLf, " ")
    SetResult message, ok

    MsgBox message, IIf(ok, vbInformation, vbExclamation), "GMWO export"
End Sub

' The error number and description are passed in rather than read from Err here.
' VBA clears Err on Exit Sub and on any On Error statement, so a helper that reaches
' for Err itself works only as long as nothing between the failure and this call
' happens to touch it - a dependency no reader should have to verify.
Private Sub ReportUnexpected(ByVal errNumber As Long, ByVal errDescription As String)
    ClearStatus
    LogLine "UNEXPECTED ERROR " & errNumber & ": " & errDescription
    SetResult "Unexpected error: " & errDescription, False
    MsgBox "Something went wrong that this workbook was not expecting." & vbLf & vbLf & _
           "Nothing has been damaged. Please try again." & vbLf & vbLf & _
           "If it keeps happening, send the " & SHEET_LOG & " sheet to your Oxford " & _
           "Economics contact - it records what happened just before this." & vbLf & vbLf & _
           "Technical detail: error " & errNumber & ", " & errDescription, _
           vbCritical, "GMWO export"
End Sub

Public Sub ClearToken()
    SetCfgValue "cfg_AccessToken", vbNullString
    LogLine "Access token cleared"
    MsgBox "Your access token has been removed from this workbook." & vbLf & vbLf & _
           "Save the file now to keep it that way.", _
           vbInformation, "GMWO export"
End Sub

' Clears the sheet the same way an import does, by calling the same code. Doing it
' by hand here once meant this button left list objects behind that a real import
' would have removed.
Public Sub ClearData()
    ClearSheet ThisWorkbook.Worksheets(SHEET_DATA)

    SetResult "Data sheet cleared.", True
    LogLine "Data sheet cleared"
End Sub

Public Sub ClearLog()
    Dim ws As Worksheet
    Dim lastRow As Long

    Set ws = ThisWorkbook.Worksheets(SHEET_LOG)
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    If lastRow > 1 Then ws.Range(ws.Rows(2), ws.Rows(lastRow)).ClearContents
End Sub

'--- Progress and logging -----------------------------------------------------

Public Sub Status(ByVal text As String)
    Application.StatusBar = "GMWO export: " & text
    DoEvents
End Sub

Public Sub ClearStatus()
    Application.StatusBar = False
End Sub

' Writes the outcome to the Last run cell. Never raises: the Config sheet ships
' protected (the API base URL cell is locked), and if a client tightens that
' protection further, or protects the sheet again by hand with formatting
' disallowed, then colouring this cell fails. That must not turn a completed export
' into "something went wrong" - RunExport's error handler would catch it after the
' work was already finished. The Log sheet has the same message either way.
Public Sub SetResult(ByVal text As String, ByVal ok As Boolean)
    Dim cell As Range

    Set cell = NamedRange("cfg_Status")
    If cell Is Nothing Then Exit Sub

    On Error Resume Next
    cell.Value = Replace$(text, vbLf, " ")
    cell.Font.Color = IIf(ok, RGB(0, 110, 0), RGB(170, 0, 0))
End Sub

' Appends a timestamped line to the Log sheet. Never raises: logging must not be
' the thing that breaks an export.
Public Sub LogLine(ByVal text As String)
    Dim ws As Worksheet
    Dim nextRow As Long

    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(SHEET_LOG)
    If ws Is Nothing Then Exit Sub

    nextRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row + 1
    If nextRow < 2 Then nextRow = 2

    ws.Cells(nextRow, 1).Value = Format$(Now, "yyyy-mm-dd hh:nn:ss")
    ws.Cells(nextRow, 2).Value = Left$(text, 32000)
End Sub

'=============================================================================
' modSelfTest.bas
'=============================================================================

Public Sub SelfTest_BuildBody()
    Dim body As String
    Dim seriesCount As Long
    Dim usedSeriesTable As Boolean
    Dim source As String

    body = BuildRequestBody(seriesCount, usedSeriesTable)

    ' The two blocks on the Selection sheet are alternatives, and a client who has
    ' filled in both gets no hint of that from the count alone. Saying which one the
    ' number came from is the whole reason this button is worth pressing twice.
    If usedSeriesTable Then
        source = "They come from the exact combinations table on the right of the " & _
                 SHEET_SELECTION & " sheet. The three lists on the left are not being used."
    Else
        source = "They come from the three lists on the left of the " & SHEET_SELECTION & _
                 " sheet - every indicator, crossed with every location and every transformation."
    End If

    LogLine "--- SelfTest_BuildBody: " & seriesCount & " series, nothing sent ---"
    LogLine body

    MsgBox "Your current selections add up to " & seriesCount & " series." & vbLf & vbLf & _
           source & vbLf & vbLf & _
           "Nothing was sent to Oxford Economics." & vbLf & vbLf & _
           "If that number is not what you expected, check your indicator and location codes on the " & _
           SHEET_SELECTION & " sheet before running a real export.", _
           vbInformation, "GMWO export"
End Sub

Public Sub SelfTest_ParseJson()
    Dim failures As Collection
    Set failures = New Collection

    LogLine "--- SelfTest_ParseJson ---"
    CheckJsonHandling failures

    Report failures
End Sub

Public Sub SelfTest_RunAll()
    Dim failures As Collection
    Set failures = New Collection

    LogLine "--- SelfTest_RunAll ---"
    RunAllChecks failures

    Report failures
End Sub

'--- Non-interactive entry point ----------------------------------------------

' Returns "" when every check passed, otherwise one line per failure.
Public Function SelfTest_RunAllQuiet() As String
    Dim failures As Collection

    Set failures = New Collection

    On Error GoTo Failed
    LogLine "--- SelfTest_RunAllQuiet ---"
    RunAllChecks failures

    SelfTest_RunAllQuiet = FailureLines(failures)
    Exit Function

Failed:
    SelfTest_RunAllQuiet = "Self-test raised error " & Err.Number & ": " & Err.Description
End Function

' The check list, in one place. The button and the build gate must run the same
' checks: listed twice, a check added for one would silently not be run by the other,
' and verify-workbook.ps1 would stop covering it without anything failing.
Private Sub RunAllChecks(ByRef failures As Collection)
    CheckJsonHandling failures
    CheckRequestBody failures
    CheckDownloadGuard failures
    CheckFileName failures
    CheckHeaderRowFormats failures
    CheckLocationList failures
    CheckConfigLock failures
End Sub

' Automation-only: pushes a csv through the real import path and inspects what
' landed on the Data sheet. Returns "" when every check passed.
Public Function SelfTest_ImportCsvQuiet(ByVal filePath As String) As String
    Dim failures As Collection
    Dim ws As Worksheet

    Set failures = New Collection

    On Error GoTo Failed
    LogLine "--- SelfTest_ImportCsvQuiet: " & filePath & " ---"

    ImportCsv filePath
    Set ws = ThisWorkbook.Worksheets(SHEET_DATA)

    Check failures, "header row imported", CStr(ws.Range("A1").Value), "Location"
    Check failures, "row count", _
          CStr(ws.Cells(ws.Rows.Count, 1).End(xlUp).Row), "4"
    Check failures, "quoted field with commas stays in one cell", _
          CStr(ws.Range("D2").Value), "a, b, c"
    Check failures, "quoted indicator name with commas stays in one cell", _
          CStr(ws.Range("B3").Value), "Consumption, private, real, LCU"
    Check failures, "trailing column not shifted by embedded commas", _
          CStr(ws.Range("E2").Value), "D7BT@UK"

    ' The locale check: without TextFileDecimalSeparator this reads as 1084667
    ' on a machine whose regional settings use a comma for decimals.
    CheckTrue failures, "108.4667 parsed as a decimal, not 1084667", _
          IsNumeric(ws.Range("C2").Value) And _
          Abs(CDbl(ws.Range("C2").Value) - 108.4667) < 0.00001

    Check failures, "no live query left behind", CStr(ws.QueryTables.Count), "0"

    ' Row 4 of the test csv carries fields that Excel's text import turns into live
    ' formulas: "=1+1", an =HYPERLINK(..) that reads another cell of this workbook,
    ' and a leading-plus field. NeutraliseFormulas has to have turned all
    ' three back into text. The single most important check here is the last one.
    CheckTrue failures, "an injected formula is not left as a formula", _
          Not ws.Range("B4").HasFormula
    Check failures, "an injected formula is kept as its own text", _
          CStr(ws.Range("B4").Value), "=1+1"
    CheckTrue failures, "an injected HYPERLINK is not left as a formula", _
          Not ws.Range("D4").HasFormula
    CheckTrue failures, "the HYPERLINK text is still readable in the cell", _
          InStr(1, CStr(ws.Range("D4").Value), "HYPERLINK", vbTextCompare) > 0
    ' Excel resolves a leading "+" to "=" as it imports, so what is kept is the
    ' formula it made rather than the "+1+2" in the file. Either way it is inert.
    CheckTrue failures, "a leading-plus field is not left as a formula", _
          Not ws.Range("E4").HasFormula
    ' The other half of the same guarantee, and the one that would break real
    ' exports if NeutraliseFormulas ever grew ambitious: a leading "-" makes a
    ' formula only when what follows is not a number, so the negative values that
    ' fill a difference or percentage-change series are numbers and must stay
    ' numbers, untouched and still numeric.
    CheckTrue failures, "a negative value is left alone, as a number", _
          IsNumeric(ws.Range("C4").Value) And _
          Abs(CDbl(ws.Range("C4").Value) - (-1.5)) < 0.00001

    Check failures, "no formulas anywhere on the sheet", CStr(FormulaCount(ws)), "0"

    ' How row 1 is presented, both ways round. The second import is the same file
    ' down the same path with only the flag changed, which is what a Classic_h
    ' export does - and it has to leave the first row looking like the data it is.
    CheckTrue failures, "row 1 is bold when the format has a header row", _
          CBool(ws.Range("A1").Font.Bold)

    ImportCsv filePath, False
    CheckTrue failures, "row 1 is left alone when the format has none", _
          Not CBool(ws.Range("A1").Font.Bold)

    SelfTest_ImportCsvQuiet = FailureLines(failures)
    Exit Function

Failed:
    SelfTest_ImportCsvQuiet = "Csv import raised error " & Err.Number & ": " & Err.Description
End Function

' Automation-only: the tblSeries path, which nothing else here reaches. That table
' ships empty, so BuildSeriesSelection always takes the cross product and
' FromSeriesTable and RowValue are never called by the other
' checks. Returns "" when every check passed.
'
' It is not on the "Check this workbook" button, and must not be put there: it writes
' to tblSeries, and a diagnostic has no business editing a client's own selections.
' It declines to run rather than touch a table that already has rows, and puts back
' what it wrote even when a check raises.
Public Function SelfTest_SeriesTableQuiet() As String
    Dim failures As Collection
    Dim lo As ListObject
    Dim fallbackTransformation As String
    Dim seriesSelection As String
    Dim seriesCount As Long
    Dim usedSeriesTable As Boolean
    Dim rowsBefore As Long
    Dim errNumber As Long
    Dim errDescription As String

    Set failures = New Collection
    rowsBefore = -1                      ' -1 means nothing has been written yet

    On Error GoTo Failed
    LogLine "--- SelfTest_SeriesTableQuiet ---"

    Set lo = FindTable("tblSeries")
    If lo Is Nothing Then
        SelfTest_SeriesTableQuiet = "tblSeries is missing from the " & SHEET_SELECTION & " sheet."
        Exit Function
    End If
    If lo.DataBodyRange Is Nothing Then
        SelfTest_SeriesTableQuiet = "tblSeries has no body row to write to."
        Exit Function
    End If
    If Application.CountA(lo.DataBodyRange) > 0 Then
        SelfTest_SeriesTableQuiet = "tblSeries already has rows, so this check did not run. " & _
            "It writes to that table and will not edit real selections."
        Exit Function
    End If

    ' Both halves of "which block was used" are checked here rather than in
    ' RunAllChecks, because this is the only entry point that knows the state of
    ' tblSeries: the guard above has just established that it is empty, and the rows
    ' below are written by this check itself. On the button, where a client may
    ' legitimately have filled that table in, neither half could be asserted.
    seriesSelection = BuildSeriesSelection(seriesCount, usedSeriesTable)
    CheckTrue failures, "an empty tblSeries leaves the three lists in charge", Not usedSeriesTable

    fallbackTransformation = DefaultTransformation()
    rowsBefore = lo.ListRows.Count

    ' Row 1 leaves Transformation and ValueType blank, so RowValue has to fall back.
    lo.DataBodyRange.Cells(1, 1).Value = "GDP"
    lo.DataBodyRange.Cells(1, 2).Value = "UK"

    ' Row 2 carries its own Transformation - the other half of RowValue.
    lo.ListRows.Add
    lo.DataBodyRange.Cells(2, 1).Value = "CPI"
    lo.DataBodyRange.Cells(2, 2).Value = "GERMANY"
    lo.DataBodyRange.Cells(2, 3).Value = "DY"

    seriesSelection = BuildSeriesSelection(seriesCount, usedSeriesTable)
    LogLine "  tblSeries selection: " & seriesSelection

    Check failures, "tblSeries is used instead of the three lists", CStr(seriesCount), "2"
    CheckTrue failures, "and says so, which is what the client is told", usedSeriesTable
    CheckContains failures, "a blank Transformation falls back to the first one", seriesSelection, _
          "{""Indicator"":""GDP"",""Location"":""UK"",""Transformation"":""" & fallbackTransformation & """}"
    CheckContains failures, "a row's own Transformation is used", seriesSelection, _
          "{""Indicator"":""CPI"",""Location"":""GERMANY"",""Transformation"":""DY""}"
    CheckMissing failures, "a blank ValueType is omitted", seriesSelection, """ValueType"""
    Check failures, "the selection is a JSON array", _
          Left$(seriesSelection, 1) & Right$(seriesSelection, 1), "[]"

    RestoreSeriesTable lo, rowsBefore
    rowsBefore = -1

    SelfTest_SeriesTableQuiet = FailureLines(failures)
    Exit Function

Failed:
    ' Read Err before cleaning up: the On Error statements below reset it.
    errNumber = Err.Number
    errDescription = Err.Description

    If rowsBefore >= 0 Then
        On Error Resume Next
        RestoreSeriesTable lo, rowsBefore
        On Error GoTo 0
    End If

    SelfTest_SeriesTableQuiet = "Series table check raised error " & errNumber & ": " & errDescription
End Function

' Puts tblSeries back as it was found - rows this check added are deleted and the
' cells it wrote are cleared. Only ever called after CountA found the table empty, so
' clearing the body cannot discard anything a client typed.
Private Sub RestoreSeriesTable(ByVal lo As ListObject, ByVal rowsBefore As Long)
    Do While lo.ListRows.Count > rowsBefore
        lo.ListRows(lo.ListRows.Count).Delete
    Loop

    If Not lo.DataBodyRange Is Nothing Then lo.DataBodyRange.ClearContents
End Sub

' Automation-only: the whole export flow with no dialogs, for a scripted live
' test. Returns the outcome message prefixed OK or FAILED.
Public Function LiveTest_RunExportQuiet() As String
    Dim message As String
    Dim ok As Boolean

    On Error GoTo Failed
    ok = RunExportFlow(message)
    LiveTest_RunExportQuiet = IIf(ok, "OK: ", "FAILED: ") & Replace$(message, vbLf, " ")
    Exit Function

Failed:
    LiveTest_RunExportQuiet = "FAILED: error " & Err.Number & " - " & Err.Description
End Function

'--- The checks ---------------------------------------------------------------

' The download guard in  That request carries the access token and its url
' comes from the API's response rather than the Config sheet, so the host is
' checked before the token is attached. These pin the comparison, including the two
' tricks a prefix test would wave through.
'
' Safe to run offline: a refused download returns its message before touching the
' network or the disk.
Private Sub CheckDownloadGuard(ByRef failures As Collection)
    Dim expected As String
    Dim probeFile As String
    Dim message As String

    expected = UrlOrigin(CfgBaseUrl())

    Check failures, "origin of the base url", expected, "https://model.oxfordeconomics.com"
    Check failures, "origin drops the path", _
          UrlOrigin("https://model.oxfordeconomics.com/api/v1/operations/23614/artifact/abc"), _
          "https://model.oxfordeconomics.com"
    Check failures, "text that is not a url has no origin", _
          UrlOrigin("not a url at all"), ""
    CheckTrue failures, "a host smuggled in as url credentials does not match", _
          UrlOrigin("https://model.oxfordeconomics.com@evil.example/x") <> expected
    CheckTrue failures, "plain http does not match https", _
          UrlOrigin("http://model.oxfordeconomics.com/api") <> expected

    ' The positive case matters as much as the refusals: this is the actual
    ' DownloadUrl recorded from the live API in CheckJsonHandling above, and the
    ' guard has to let it through or exports stop working.
    Check failures, "the genuine artifact url is allowed through", _
          UrlOrigin("https://model.oxfordeconomics.com/api/v1/operations/23614/artifact/411cece1-104f-415e-aac9-1f7d740dac26"), _
          expected

    ' Through the real entry point, not just the helper.
    probeFile = ThisWorkbook.Path & "\gmwo-download-guard-check.tmp"

    message = HttpDownloadToFile("https://evil.example/artifact/1", probeFile)
    CheckTrue failures, "download from another host is refused", Len(message) > 0
    CheckTrue failures, "refused download writes no file", Len(Dir$(probeFile)) = 0

    message = HttpDownloadToFile("https://model.oxfordeconomics.com@evil.example/a", probeFile)
    CheckTrue failures, "download from a credentials-in-url host is refused", Len(message) > 0
    CheckTrue failures, "that refusal writes no file either", Len(Dir$(probeFile)) = 0
End Sub

' SafeFileName. The artifact filename arrives in the API's response and
' is the only thing between that response and a file written to the client's disk,
' so what it refuses matters as much as what it tidies up.
Private Sub CheckFileName(ByRef failures As Collection)
    Check failures, "an ordinary artifact name is left alone", _
          SafeFileName("series-2020-2023_Oct23_1 25yr.csv"), _
          "series-2020-2023_Oct23_1 25yr.csv"
    Check failures, "a relative path cannot escape the output folder", _
          SafeFileName("..\..\evil.csv"), ".._.._evil.csv"
    Check failures, "an absolute path cannot be smuggled in", _
          SafeFileName("C:\Windows\System32\evil.csv"), _
          "C__Windows_System32_evil.csv"
    Check failures, "a UNC path cannot be smuggled in", _
          SafeFileName("\\server\share\evil.csv"), "__server_share_evil.csv"

    ' The extension is forced, so a response cannot have this workbook write a file
    ' Windows would treat as anything other than a csv.
    Check failures, "another spreadsheet extension is not trusted", _
          SafeFileName("quarterly.xlsx"), "quarterly.xlsx.csv"
    Check failures, "an executable extension is not trusted", _
          SafeFileName("update.exe"), "update.exe.csv"
    Check failures, "no extension at all gets one", _
          SafeFileName("series"), "series.csv"
    Check failures, "the extension check ignores case", _
          SafeFileName("SERIES.CSV"), "SERIES.CSV"
    Check failures, "an empty name falls back to a usable one", _
          SafeFileName(""), "gmwo-export.csv"
End Sub

' FormatHasHeaderRow, which is what decides whether modImport bolds and
' freezes the first row of the Data sheet. Classic_h is the only format whose first
' line is a series rather than column headings, so it is the only one that answers
' False - and the only one where bolding row 1 would be labelling data as a heading.
Private Sub CheckHeaderRowFormats(ByRef failures As Collection)
    CheckTrue failures, "Classic_h has no header row", _
          Not FormatHasHeaderRow("Classic_h")
    CheckTrue failures, "the format name is matched whatever its case", _
          Not FormatHasHeaderRow("classic_h")
    CheckTrue failures, "Classic_v is not caught by the Classic_h test", _
          FormatHasHeaderRow("Classic_v")
    CheckTrue failures, "Default has a header row", _
          FormatHasHeaderRow("Default")

    ' A client can type into the Output format box, and the API may add formats this
    ' workbook has never heard of. Either way the first row stays bold, which is the
    ' milder of the two ways to be wrong.
    CheckTrue failures, "an unrecognised format is assumed to have one", _
          FormatHasHeaderRow("SomethingTheApiAddedLater")
End Sub

' The Location dropdowns and the list behind them.
'
' Those codes are the Global Economic Model's own sector list, read out of the model
' repo when the workbook was built and written down the right of the Start here
' sheet; loc_Codes names that column so data validation on the Selection sheet can
' reach it, which it cannot do with a plain cross-sheet reference.
'
' Both Location columns refuse anything not in the list, so this is checked from the
' other direction to everything else here: if the list or the rule has gone, a client
' is not merely unprotected, they may be unable to enter a location at all. Pasting
' still bypasses Excel validation entirely - nothing in a workbook can prevent that -
' which is the more reason to know the rule itself is still in place.
Private Sub CheckLocationList(ByRef failures As Collection)
    Dim codes As Range
    Dim locations As ListObject
    Dim series As ListObject

    Set codes = NamedRange("loc_Codes")
    If codes Is Nothing Then
        Fail failures, "the location code list (loc_Codes) is missing from this workbook"
        Exit Sub
    End If

    ' The model has upwards of a hundred sectors. An exact count would fail every time
    ' the model gains one, so this only catches a list that arrived empty or truncated.
    CheckTrue failures, "the location code list is populated", Application.CountA(codes) > 50

    Set locations = FindTable("tblLocations")
    If locations Is Nothing Then
        Fail failures, "tblLocations is missing, so its dropdown cannot be checked"
    Else
        Check failures, "the Location list only accepts those codes", _
              ValidationSource(locations.Range.Cells(2, 1)), "=loc_Codes"
    End If

    Set series = FindTable("tblSeries")
    If series Is Nothing Then
        Fail failures, "tblSeries is missing, so its Location column cannot be checked"
    Else
        Check failures, "the exact combinations table checks Location the same way", _
              ValidationSource(series.ListColumns("Location").DataBodyRange.Cells(1, 1)), "=loc_Codes"
    End If
End Sub

' What a cell's list validation reads from, or "" when it has no validation at all.
' Validation.Formula1 raises rather than returning empty on a cell with none, and an
' unvalidated cell is exactly what this is looking for.
Private Function ValidationSource(ByVal cell As Range) As String
    On Error Resume Next
    ValidationSource = cell.Validation.Formula1
    On Error GoTo 0
End Function

' The API base URL cell. Its value decides where the access token is sent, so it
' ships locked behind sheet protection - see the note in build-workbook.ps1. These
' checks fail if the file has been altered since it was built, which is the point.
'
' If a client has been asked to change the base URL and has unprotected the sheet
' to do it, expect these to fail: that is the check working, not the file being
' broken.
Private Sub CheckConfigLock(ByRef failures As Collection)
    Dim ws As Worksheet
    Dim baseUrl As Range

    Set ws = ThisWorkbook.Worksheets(SHEET_CONFIG)
    CheckTrue failures, "the Config sheet is protected", ws.ProtectContents

    Set baseUrl = NamedRange("cfg_BaseUrl")
    If baseUrl Is Nothing Then
        Fail failures, "cfg_BaseUrl is missing, so its lock cannot be checked"
        Exit Sub
    End If
    CheckTrue failures, "the API base URL cell is locked", CBool(baseUrl.Locked)

    ' The cells a client types into, and the two the code itself writes to. A lock
    ' on any of these would break the workbook rather than protect it.
    CheckTrue failures, "the access token cell is still editable", _
          Not CBool(NamedRange("cfg_AccessToken").Locked)
    CheckTrue failures, "the forecast path cell is still editable", _
          Not CBool(NamedRange("cfg_ForecastPath").Locked)
    CheckTrue failures, "the output folder cell is still editable", _
          Not CBool(NamedRange("cfg_OutputFolder").Locked)
    CheckTrue failures, "the status cell the code writes to is still editable", _
          Not CBool(NamedRange("cfg_Status").Locked)
End Sub

Private Sub CheckJsonHandling(ByRef failures As Collection)
    Dim postResponse As String
    Dim awaitResponse As String

    ' Both payloads are copied from the cell outputs in export/export.ipynb.
    postResponse = "{""Artifacts"": [], ""Resources"": [], ""Id"": ""23614""," & _
        " ""CreatedAt"": ""2023-10-16T10:30:14.22+00:00"", ""StartedAt"": null," & _
        " ""CompletedAt"": null, ""Status"": ""Queued"", ""Duration"": null," & _
        " ""FailureReason"": null, ""Name"": null}"

    awaitResponse = "{""Artifacts"": [{""Id"": ""411cece1-104f-415e-aac9-1f7d740dac26""," & _
        " ""Filename"": ""series-2020-2023_Oct23_1 25yr.csv"", ""Type"": ""text/csv""," & _
        " ""DownloadUrl"": ""https://model.oxfordeconomics.com/api/v1/operations/23614/artifact/411cece1-104f-415e-aac9-1f7d740dac26""}]," & _
        " ""Resources"": [{""Id"": ""2198fad7-c646-43f7-b81c-f86dd4eea113""," & _
        " ""Path"": ""/oxford-economics/releases/GEM/Oct23_1 25yr"", ""Version"": 0, ""Role"": ""Input""}]," & _
        " ""Id"": ""23614"", ""CreatedAt"": ""2023-10-16T10:30:14.22+00:00""," & _
        " ""Status"": ""Succeeded"", ""Duration"": 35151, ""FailureReason"": null, ""Name"": null}"

    Check failures, "operation id from the POST response", _
          JsonScalar(postResponse, "Id"), "23614"
    Check failures, "status from the POST response", _
          JsonScalar(postResponse, "Status"), "Queued"
    Check failures, "null reads as empty", _
          JsonScalar(postResponse, "FailureReason"), ""
    Check failures, "numeric value", _
          JsonScalar(awaitResponse, "Duration"), "35151"
    Check failures, "status from the await response", _
          JsonScalar(awaitResponse, "Status"), "Succeeded"
    Check failures, "artifact filename", _
          JsonScalar(awaitResponse, "Filename"), "series-2020-2023_Oct23_1 25yr.csv"
    Check failures, "artifact download url", _
          JsonScalar(awaitResponse, "DownloadUrl"), _
          "https://model.oxfordeconomics.com/api/v1/operations/23614/artifact/411cece1-104f-415e-aac9-1f7d740dac26"
    Check failures, "absent key reads as empty", _
          JsonScalar(awaitResponse, "NoSuchKey"), ""
    Check failures, "a longer key is not matched by a shorter one", _
          JsonScalar("{""ForecastId"": ""nope"", ""Id"": ""yes""}", "Id"), "yes"

    ' Pins the known limitation rather than pretending it is not there: JsonScalar
    ' is flat, so on an await response "Id" finds Artifacts[0].Id, not the
    ' operation id. modExport therefore only ever reads Id from the POST reply.
    Check failures, "await ""Id"" is the artifact id, by design", _
          JsonScalar(awaitResponse, "Id"), "411cece1-104f-415e-aac9-1f7d740dac26"

    ' Escaping, both directions.
    Check failures, "unescapes quotes and backslashes", _
          JsonScalar("{""X"":""a\""b\\c""}", "X"), "a""b\c"
    Check failures, "escapes quotes and backslashes", _
          JsonEscape("a""b\c"), "a\""b\\c"
    Check failures, "escapes newlines", _
          JsonEscape("a" & vbCrLf & "b"), "a\nb"
    Check failures, "leaves an ordinary forecast path alone", _
          JsonEscape("/oxford-economics/releases/Global Economic Model/Jul26_2 25yr"), _
          "/oxford-economics/releases/Global Economic Model/Jul26_2 25yr"
End Sub

' Exercises modConfig + modExport against the workbook's own sheets.
Private Sub CheckRequestBody(ByRef failures As Collection)
    Dim body As String
    Dim seriesCount As Long
    ' Read but not asserted on: this runs on the button, where tblSeries may well have
    ' rows a client put there. SelfTest_SeriesTableQuiet pins both of its values.
    Dim usedSeriesTable As Boolean
    Dim indicators As Collection
    Dim locations As Collection
    Dim transformations As Collection
    Dim t As Long

    Set indicators = TableColumn("tblIndicators", "Indicator")
    Set locations = TableColumn("tblLocations", "Location")
    Set transformations = TableColumn("tblTransformations", "Transformation")

    body = BuildRequestBody(seriesCount, usedSeriesTable)
    LogLine "  body: " & body

    Check failures, "series count is indicators x locations x transformations", _
          CStr(seriesCount), CStr(indicators.Count * locations.Count * transformations.Count)

    ' Several transformations in one request: each must reach the body, and the
    ' same indicator+location must appear once per transformation.
    For t = 1 To transformations.Count
        CheckContains failures, "transformation " & transformations(t) & " is in the request", _
              body, """Transformation"":""" & transformations(t) & """"
    Next t

    If transformations.Count > 1 And indicators.Count > 0 And locations.Count > 0 Then
        CheckTrue failures, "one indicator+location pair repeats per transformation", _
              CountOccurrences(body, """Indicator"":""" & indicators(1) & _
                                     """,""Location"":""" & locations(1) & """") _
              = transformations.Count
    End If

    CheckContains failures, "forecast path is sent", body, _
          """InputForecast"":""" & CfgValue("cfg_ForecastPath") & """"
    CheckContains failures, "range is sent", body, _
          """Range"":{""From"":""" & CfgValue("cfg_From") & _
          """,""To"":""" & CfgValue("cfg_To") & """}"
    CheckContains failures, "series selection is an array", body, """SeriesSelection"":["

    ' Only that it is present and non-empty: the value carries a timestamp, so
    ' there is nothing stable to compare it against.
    CheckContains failures, "operation name is sent", body, """OperationName"":"""

    If indicators.Count > 0 And locations.Count > 0 And transformations.Count > 0 Then
        CheckContains failures, "first series is well formed", body, _
              "{""Indicator"":""" & indicators(1) & _
              """,""Location"":""" & locations(1) & _
              """,""Transformation"":""" & transformations(1) & """}"
    End If

    ' Optional properties are omitted at their defaults, as the notebook describes.
    If StrComp(CfgValue("cfg_Format"), "Default", vbTextCompare) = 0 Then
        CheckMissing failures, "Format omitted when Default", body, """Format"""
    End If
    If StrComp(CfgValue("cfg_ValueType"), "Variable", vbTextCompare) = 0 Then
        CheckMissing failures, "ValueType omitted when Variable", body, """ValueType"""
    End If
    If Not CfgBool("cfg_AnnualRollup") Then
        CheckMissing failures, "AnnualRollup omitted when false", body, """AnnualRollup"""
    End If

    Check failures, "body is a single JSON object", _
          Left$(body, 1) & Right$(body, 1), "{}"

    ' Touches modHttp so a compile error in it cannot hide behind never being called.
    SleepResponsive 0
End Sub

'--- Assertions ---------------------------------------------------------------

Private Sub Check(ByRef failures As Collection, ByVal description As String, _
                  ByVal actual As String, ByVal expected As String)
    If actual = expected Then
        LogLine "  pass  " & description
    Else
        Fail failures, description & "  |  expected [" & expected & "]  got [" & actual & "]"
    End If
End Sub

Private Sub CheckTrue(ByRef failures As Collection, ByVal description As String, _
                      ByVal condition As Boolean)
    If condition Then
        LogLine "  pass  " & description
    Else
        Fail failures, description
    End If
End Sub

Private Sub CheckContains(ByRef failures As Collection, ByVal description As String, _
                          ByVal haystack As String, ByVal needle As String)
    If InStr(1, haystack, needle, vbBinaryCompare) > 0 Then
        LogLine "  pass  " & description
    Else
        Fail failures, description & "  |  did not find [" & needle & "]"
    End If
End Sub

Private Sub CheckMissing(ByRef failures As Collection, ByVal description As String, _
                         ByVal haystack As String, ByVal needle As String)
    If InStr(1, haystack, needle, vbBinaryCompare) = 0 Then
        LogLine "  pass  " & description
    Else
        Fail failures, description & "  |  unexpectedly found [" & needle & "]"
    End If
End Sub

' Formulas left on a sheet. SpecialCells raises rather than returning an empty
' range when there are none, so the answer to "none at all" arrives as an error.
Private Function FormulaCount(ByVal ws As Worksheet) As Long
    Dim found As Range

    On Error Resume Next
    Set found = ws.UsedRange.SpecialCells(xlCellTypeFormulas)
    On Error GoTo 0

    If Not found Is Nothing Then FormulaCount = found.Cells.Count
End Function

Private Function CountOccurrences(ByVal haystack As String, ByVal needle As String) As Long
    Dim position As Long

    If Len(needle) = 0 Then Exit Function
    position = InStr(1, haystack, needle, vbBinaryCompare)
    Do While position > 0
        CountOccurrences = CountOccurrences + 1
        position = InStr(position + Len(needle), haystack, needle, vbBinaryCompare)
    Loop
End Function

Private Sub Fail(ByRef failures As Collection, ByVal text As String)
    failures.Add text
    LogLine "  FAIL  " & text
End Sub

' What the two Quiet entry points return: "" when nothing failed, otherwise one
' failure per line, which is what build-workbook.ps1 and verify-workbook.ps1 print.
Private Function FailureLines(ByVal failures As Collection) As String
    Dim i As Long

    For i = 1 To failures.Count
        FailureLines = FailureLines & failures(i) & vbLf
    Next i
End Function

Private Sub Report(ByRef failures As Collection)
    If failures.Count = 0 Then
        MsgBox "This workbook checked itself over and everything is working." & vbLf & vbLf & _
               "If an export is still failing, the problem is your access token, your forecast path, " & _
               "or the Oxford Economics service - not this file.", _
               vbInformation, "GMWO export"
    Else
        MsgBox failures.Count & " of this workbook's own checks failed." & vbLf & vbLf & _
               "Please ask whoever sent you this file for a fresh copy, and send them the " & _
               SHEET_LOG & " sheet.", _
               vbCritical, "GMWO export"
    End If
End Sub
