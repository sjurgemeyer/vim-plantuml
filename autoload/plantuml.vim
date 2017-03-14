if exists("g:plantuml_jar_path")
    let s:jar_path = g:plantuml_jar_path
else
    let s:jar_path = expand("<sfile>:p:h") . "/../plantuml.jar"
endif

function! s:tempBuffer()
    let temp_file = tempname()

    " open the preview window to the temp file
    silent exe ":pedit! " . temp_file

    " select the temp buffer as active
    wincmd P

    " set options for temp buffer
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal nowrap
    setlocal bufhidden=delete
    setlocal winheight=40

    setlocal filetype=plantumlpreview
    return temp_file
endfunction

function! plantuml#updatePreview(args) abort

    let tmpfname = tempname()
    let erroutput = tempname()
    call s:mungeDiagramInTmpFile(tmpfname)
    let b:plantuml_preview_fname = fnamemodify(tmpfname,  ':r') . '.utxt'

    let cmd = "java -jar ". s:jar_path ." -utxt " . tmpfname . " 2>" . erroutput

    call system(cmd)
    if v:shell_error == 0
        call s:updateBuffer(a:args)
    else
        let lines = readfile(erroutput)
        let error = ""
        for line in lines
            if line =~ ' in file'
                let line = split(line, ' in file')[0] . ", "
            endif
            let error = error . line
        endfor

        echoerr error
    endif
endfunction

function! s:updateBuffer(args) abort
    call s:insertDiagram(b:plantuml_preview_fname)
    call s:addTitle()
endfunction

function! s:insertDiagram(fname) abort

    let temp_file = s:tempBuffer()
    call s:readWithoutStoringAsAltFile(a:fname)

    wincmd p " change back to the source buffer
endfunction

function! s:readWithoutStoringAsAltFile(fname) abort
    let oldcpoptions = &cpoptions
    set cpoptions-=a
    exec "read " . a:fname
    let &cpoptions = oldcpoptions
endfunction

function! s:mungeDiagramInTmpFile(fname) abort
    execute "write " . a:fname
    call s:convertNonAsciiSupportedSyntax(a:fname)
endfunction

function! s:convertNonAsciiSupportedSyntax(fname) abort
    let oldbuf = bufnr("")

    exec 'edit ' . a:fname
    let tmpbufnr = bufnr("")

    /@startuml/,/@enduml/s/^\s*\(boundary\|database\|entity\|control\)/participant/e
    /@startuml/,/@enduml/s/^\s*\(end \)\?\zsref\>/note/e
    /@startuml/,/@enduml/s/^\s*ref\>/note/e
    /@startuml/,/@enduml/s/|||/||4||/e
    /@startuml/,/@enduml/s/\.\.\.\([^.]*\)\.\.\./==\1==/e
    write

    exec oldbuf . "buffer"
    exec tmpbufnr. "bwipe!"
endfunction

function! s:addTitle() abort
    let lnum = search('^title ', 'n')
    if !lnum
        return
    endif

    let title = substitute(getline(lnum), '^title \(.*\)', '\1', '')

    call append(0, "")
    call append(0, repeat("^", len(title)+6))
    call append(0, "   " . title)
endfunction
