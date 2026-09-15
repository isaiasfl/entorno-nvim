# LazyGit: inventario completo de teclas predeterminadas

Versión local: 0.65.0. Captura de `lazygit --config` del 13 de septiembre de 2026.
No contiene configuración personal. Los nombres de acciones se conservan en
el idioma original para poder contrastarlos con la aplicación.

Cada bloque es un contexto: `files`, `branches`, `commits`, etc. Una misma
tecla puede realizar acciones distintas según el panel. `universal` recoge
los valores generales. `alt` indica una combinación alternativa.

Advertencia: reset, descarte, borrado, rebase, force checkout y reescritura de
commits pueden perder trabajo o cambiar historia compartida. Este listado no
es una recomendación de ejecutarlos. Consulte `?` en la aplicación antes de actuar.

Volver a la [guía completa](guia-completa-teclas.md).

```yaml
keybinding:
    universal:
        quit: q
        quit-alt1: <ctrl+c>
        suspendApp: <ctrl+z>
        return: <esc>
        quitWithoutChangingDirectory: Q
        togglePanel: <tab>
        prevItem: <up>
        nextItem: <down>
        prevItem-alt: k
        nextItem-alt: j
        prevPage: ','
        nextPage: .
        scrollLeft: H
        scrollRight: L
        gotoTop: <
        gotoBottom: '>'
        gotoTop-alt: <home>
        gotoBottom-alt: <end>
        toggleRangeSelect: v
        rangeSelectDown: <shift+down>
        rangeSelectUp: <shift+up>
        prevBlock: <left>
        nextBlock: <right>
        prevBlock-alt: h
        nextBlock-alt: l
        nextBlock-alt2: <tab>
        prevBlock-alt2: <backtab>
        jumpToBlock:
            - "1"
            - "2"
            - "3"
            - "4"
            - "5"
        focusMainView: "0"
        nextMatch: "n"
        prevMatch: "N"
        startSearch: /
        moveWordLeft: <ctrl+left>
        moveWordRight: <ctrl+right>
        backspaceWord: <ctrl+backspace>
        forwardDeleteWord: <ctrl+delete>
        optionMenu: '?'
        select: <space>
        goInto: <enter>
        confirm: <enter>
        confirmMenu: <enter>
        confirmSuggestion: <enter>
        confirmInEditor: <ctrl+enter>
        confirmInEditor-alt: <ctrl+s>
        remove: d
        new: "n"
        newWorktree: w
        edit: e
        openFile: o
        scrollUpMain: <pgup>
        scrollDownMain: <pgdown>
        scrollUpMain-alt1: K
        scrollDownMain-alt1: J
        scrollUpMain-alt2: <ctrl+u>
        scrollDownMain-alt2: <ctrl+d>
        executeShellCommand: ':'
        createRebaseOptionsMenu: m
        pushFiles: P
        pullFiles: p
        refresh: R
        createPatchOptionsMenu: <ctrl+p>
        nextTab: ']'
        prevTab: '['
        nextScreenMode: +
        prevScreenMode: _
        cycleDiffRenderers: '|'
        cycleDiffRenderersReverse: \
        undo: z
        redo: Z
        filteringMenu: <ctrl+s>
        diffingMenu: W
        diffingMenu-alt: <ctrl+e>
        copyToClipboard: <ctrl+o>
        openRecentRepos: <ctrl+r>
        submitEditorText: <enter>
        extrasMenu: '@'
        toggleWhitespaceInDiffView: <ctrl+w>
        increaseContextInDiffView: '}'
        decreaseContextInDiffView: '{'
        increaseRenameSimilarityThreshold: )
        decreaseRenameSimilarityThreshold: (
        openDiffTool: <ctrl+t>
        editConfig: <alt+shift+c>
    status:
        checkForUpdate: u
        recentRepos: <enter>
        allBranchesLogGraph: a
        allBranchesLogGraphReverse: A
    files:
        commitChanges: c
        commitChangesWithoutHook: w
        amendLastCommit: A
        commitChangesWithEditor: C
        findBaseCommitForFixup: <ctrl+f>
        confirmDiscard: x
        ignoreFile: i
        refreshFiles: r
        stashAllChanges: s
        viewStashOptions: S
        toggleStagedAll: a
        viewResetOptions: D
        fetch: f
        toggleTreeView: '`'
        openMergeOptions: M
        openStatusFilter: <ctrl+b>
        copyFileInfoToClipboard: "y"
        collapseAll: '-'
        expandAll: =
    branches:
        createPullRequest: o
        viewPullRequestOptions: O
        openPullRequestInBrowser: G
        copyPullRequestURL: <ctrl+y>
        checkoutBranchByName: c
        forceCheckoutBranch: F
        checkoutPreviousBranch: '-'
        rebaseBranch: r
        renameBranch: R
        mergeIntoCurrentBranch: M
        moveCommitsToNewBranch: "N"
        viewGitFlowOptions: i
        fastForward: f
        createTag: T
        pushTag: P
        setUpstream: u
        fetchRemote: f
        addForkRemote: F
        sortOrder: s
    commits:
        squashDown: s
        renameCommit: r
        renameCommitWithEditor: R
        viewResetOptions: g
        markCommitAsFixup: f
        setFixupMessage: c
        createFixupCommit: F
        squashAboveCommits: S
        moveDownCommit: [<ctrl+j>, <alt-down>]
        moveUpCommit: [<ctrl+k>, <alt-up>]
        amendToCommit: A
        resetCommitAuthor: a
        pickCommit: p
        revertCommit: t
        cherryPickCopy: C
        pasteCommits: V
        markCommitAsBaseForRebase: B
        tagCommit: T
        checkoutCommit: <space>
        resetCherryPick: <ctrl+r>
        copyCommitAttributeToClipboard: "y"
        openLogMenu: <ctrl+l>
        openInBrowser: o
        openPullRequestInBrowser: G
        viewBisectOptions: b
        startInteractiveRebase: i
        selectCommitsOfCurrentBranch: '*'
    amendAttribute:
        resetAuthor: a
        setAuthor: A
        addCoAuthor: c
    stash:
        popStash: g
        renameStash: r
    commitFiles:
        checkoutCommitFile: c
    main:
        prevHunk: [<left>, h]
        nextHunk: [<right>, l]
        toggleSelectHunk: a
        pickBothHunks: b
        editSelectHunk: E
    submodules:
        init: i
        update: u
        bulkMenu: b
    commitMessage:
        commitMenu: <ctrl+o>
```
