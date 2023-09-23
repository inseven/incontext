
function renderDocumentHTML(document)
    local html = document.html
    if html then
        eval(html, document.sourcePath)
    end
end
