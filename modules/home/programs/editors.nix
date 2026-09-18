# Editors — plan §35 (VS Code) and §36 (Zed).
#
# Both are listed in the plan's priority theming set (§34) and its regression
# checklist (§50). VS Code was not previously installed, so it is added here;
# without it those checklist items cannot be satisfied and the `code` dock pin
# would never resolve.
#
# Transparency for both comes from the compositor (Hyprland's readable-opacity
# window rule), never from application hacks — plan §35 is explicit about that.
{
  lib,
  pkgs,
  rice,
  ...
}:
{
  ## VS Code — plan §35 ####################################################
  programs.vscode = {
    enable = true;

    profiles.default = {
      # Stylix themes VS Code's colours by default; workbench.colorTheme
      # below overrides that specifically to pin Catppuccin Macchiato,
      # so the extension has to come along with it.
      extensions = [ pkgs.vscode-extensions.catppuccin.catppuccin-vsc ];

      userSettings = {
        "workbench.colorTheme" = lib.mkForce "Catppuccin Macchiato";

        # Fonts are deliberately NOT set here. Stylix's VS Code target already
        # applies rice.fonts to every font key VS Code has, including the
        # pt-to-px conversion editor.fontSize needs — plan §34 says to use
        # Stylix where it is supported, and this is one of those places.
        "editor.fontLigatures" = true;
        "terminal.integrated.fontFamily" = "'${rice.fonts.mono.name}'";

        # Inter for the chrome, JetBrainsMono for the code (§13).
        "window.density.editorTabHeight" = "compact";
        "workbench.tree.indent" = 14;

        # The compositor draws the rounded, translucent frame; VS Code's own
        # title bar would sit inside it and look wrong.
        "window.titleBarStyle" = "custom";
        "window.menuBarVisibility" = "toggle";

        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "boundary";
        "files.trimTrailingWhitespace" = true;

        # Wayland-native rather than XWayland; NIXOS_OZONE_WL is exported in
        # the Hyprland env block, and this makes VS Code honour it.
        "window.experimental.useSandbox" = false;

        # Carried over from the pre-Nix Settings Sync profile below. Dropped:
        # Windows-only paths (msys64, Android SDK), the macOS leetcode path
        # (rewritten for this $HOME), and workbench.colorTheme, which Stylix
        # already owns above.
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1;

        "explorer.confirmDelete" = false;
        "explorer.confirmPasteNative" = false;
        "explorer.confirmDragAndDrop" = false;

        "git.autofetch" = true;
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        "git.openRepositoryInParentFolders" = "always";

        "editor.tabSize" = 2;
        "editor.autoIndentOnPaste" = true;
        "editor.unicodeHighlight.invisibleCharacters" = false;
        "editor.accessibilitySupport" = "off";

        "workbench.iconTheme" = "material-icon-theme";
        "workbench.editor.empty.hint" = "hidden";
        "workbench.browser.enableChatTools" = true;

        "diffEditor.ignoreTrimWhitespace" = false;

        "typescript.updateImportsOnFileMove.enabled" = "always";
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "python.analysis.typeCheckingMode" = "standard";

        "[typescript]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "[javascript]" = {
          "editor.defaultFormatter" = "vscode.typescript-language-features";
        };
        "[typescriptreact]" = {
          "editor.defaultFormatter" = "rvest.vs-code-prettier-eslint";
        };
        "[html]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[cpp]" = {
          "editor.defaultFormatter" = "ms-vscode.cpptools";
        };
        "[python]" = {
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.defaultColorDecorators" = "never";
          "editor.formatOnType" = true;
          "editor.wordBasedSuggestions" = "off";
        };

        "makefile.configureOnOpen" = true;
        "biome.suggestInstallingGlobally" = false;
        "markdown-pdf.format" = "Legal";
        "livePreview.notifyOnOpenLooseFile" = false;
        "postman.mcp.notifications.postmanMCP" = false;

        "pros.Enable Analytics" = false;
        "pros.Show Welcome On Startup" = false;

        "leetcode.workspaceFolder" = "/home/diamondjdev/.leetcode";
        "leetcode.defaultLanguage" = "python";
        "leetcode.hint.configWebviewMarkdown" = false;
        "leetcode.hint.commandShortcut" = false;

        "go.toolsManagement.autoUpdate" = true;

        "security.workspace.trust.untrustedFiles" = "open";
        "security.promptForLocalFileProtocolHandling" = false;

        "remote.portsAttributes" = {
          "3001" = {
            "protocol" = "https";
          };
        };

        # GitHub Copilot / Chat
        "github.copilot.enable" = {
          "*" = true;
          "plaintext" = false;
          "markdown" = false;
          "scminput" = false;
          "typescript" = true;
        };
        "github.copilot.nextEditSuggestions.enabled" = true;
        "chat.mcp.gallery.enabled" = true;
        "chat.agent.maxRequests" = 50;
        "chat.editing.confirmEditRequestRemoval" = false;
        "chat.editing.confirmEditRequestRetry" = false;
        "chat.viewSessions.orientation" = "stacked";
        "chat.tools.terminal.autoApprove" = {
          "node" = true;
          "npm run test" = true;
          "pnpm" = true;
        };
        "chat.tools.urls.autoApprove" = {
          "https://raw.githubusercontent.com" = {
            "approveRequest" = false;
            "approveResponse" = true;
          };
        };
        "chat.instructionsFilesLocations" = {
          ".github/instructions" = true;
          ".claude/rules" = true;
          "~/.copilot/instructions" = true;
          "~/.claude/rules" = true;
        };

        # Claude Code extension
        "claudeCode.selectedModel" = "claude-sonnet-4.5";
        "claudeCode.disableLoginPrompt" = true;
        "claudeCode.respectGitIgnore" = false;
        "claudeCode.preferredLocation" = "panel";

        # Stylix themes VS Code directly; Settings Sync should not touch it.
        "settingsSync.ignoredExtensions" = [
          "stylix.stylix"
        ];
      };
    };
  };

  ## Zed — plan §36 ########################################################
  programs.zed-editor = {
    enable = true;

    userSettings = {
      # Stylix's Zed target also sets these, so they are forced: the plan
      # wants font sizes centralised in settings.nix (§13), and Stylix picks
      # a different size for the buffer font than the one declared there.
      # §12 calls for exactly this kind of targeted override.
      ui_font_family = lib.mkForce rice.fonts.ui.name;
      ui_font_size = lib.mkForce rice.fonts.sizes.launcher;
      buffer_font_family = lib.mkForce rice.fonts.mono.name;
      buffer_font_size = lib.mkForce rice.fonts.sizes.terminal;

      theme = lib.mkForce {
        mode = "dark";
        dark = "Catppuccin Mocha";
        light = "Catppuccin Latte";
      };

      # Zed ships its own titlebar; hiding the system one keeps the rounded
      # compositor frame clean (§36).
      title_bar.show = false;

      terminal = {
        font_family = rice.fonts.mono.name;
        font_size = rice.fonts.sizes.terminal;
        shell.program = "zsh";
      };

      # Telemetry off by default — not a theming concern, but it is the kind
      # of setting that should be declared rather than clicked.
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
    };

    extensions = [
      "catppuccin"
      "nix"
    ];
  };

  # zed-editor was previously installed via home.packages; the module
  # installs it now, so the bare package entry is dropped in
  # modules/home/default.nix to avoid two copies on PATH.
}
