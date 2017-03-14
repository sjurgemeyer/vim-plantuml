if exists("b:loaded_plantuml")
    finish
endif
let b:loaded_plantuml=1

autocmd bufwritepost *.uml silent call plantuml#updatePreview()
