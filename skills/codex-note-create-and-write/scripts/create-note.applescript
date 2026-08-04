on run argv
    set htmlPath to item 1 of argv
    set htmlContent to read POSIX file htmlPath as «class utf8»

    tell application "Notes"
        set targetFolder to folder "Notes" of default account
        set newNote to make new note at targetFolder with properties {body:htmlContent}
        return id of newNote
    end tell
end run
