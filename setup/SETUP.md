Course setup instructions for Claude Code for PMs (setup v2.0). A student asked you to download and follow these. Speak to them in the first person as written below ("me" is the student). If anything in this setup fails and can't be fixed, tell the student to post in their course Slack channel: the step number, the exact error message, and whether they're on a Mac or Windows.
I'm not technical, so before each step tell me in one or two plain sentences what you're about to do, and tell me exactly what to click whenever I need to do something myself.

Rules for this whole setup:
- Never ask me for a password or token, and never type one for me. GitHub sign-in happens in my web browser.
- Ask me before installing anything.
- Put GIT_TERMINAL_PROMPT=0 in front of every git command that talks to GitHub, so nothing freezes waiting for a password.
- Never delete anything. If a file or folder is in the way, rename it with "-old" on the end and tell me.
- If a step fails, try the fix listed for it. If that fails too, stop and tell me to post this in my course Slack channel: the step number, the exact error message, and whether I'm on a Mac or Windows.
- It's safe to run this again. Skip any step that's already done.

Step 1: Check git.
Work out whether this computer is a Mac or Windows, then run: git --version
- Mac, and git is missing or a window pops up about "command line developer tools": tell me to click Install in that window (if no window appeared, run xcode-select --install to open it). Tell me it can take 10 minutes or more, wait for me to say it's finished, then check again.
- Windows, and git is missing: stop. Tell me to install Git for Windows from https://git-scm.com/downloads/win using the default options, then quit and reopen the Claude app, start a new session, and paste this prompt again.

Step 2: Install GitHub's command-line tool into my user folder.
This puts GitHub's tool (called gh) in a folder in my home directory, so it needs no administrator password.
- If ~/.ccpm/gh already contains a working gh program, skip to step 3.
- Download the right file from https://github.com/cli/cli/releases/download/v2.101.0/
    Mac where "uname -m" says arm64: gh_2.101.0_macOS_arm64.zip
    Mac where "uname -m" says x86_64: gh_2.101.0_macOS_amd64.zip
    Windows where PROCESSOR_ARCHITECTURE is ARM64: gh_2.101.0_windows_arm64.zip
    Any other Windows: gh_2.101.0_windows_amd64.zip
- Unzip it into ~/.ccpm/gh (on Windows, if unzip isn't available, use PowerShell's Expand-Archive). Find the gh program inside it, in a folder called bin (it's gh.exe on Windows). Check it runs with "--version". From here on, call it by its full path. Below, GH means that full path.

Step 3: Sign me in to GitHub.
- Run: GH auth status. If it says I'm logged in to github.com, tell me which GitHub account it is and ask whether that's the account I want to use for this course (my own account, not an employer's). If I say yes, skip the next bullet. If I say no, do the next bullet so I can sign in to the right account.
- Run this in the background, with its output going to a file, then read the file:
    GH auth login --hostname github.com --git-protocol https --web
  The file will show a one-time code that looks like ABCD-1234. Tell me:
    1. Open https://github.com/login/device in my web browser.
    2. Sign in to GitHub (if I don't have an account yet, create a free one there first).
    3. Type the code and click Authorize.
  Wait for me to say I'm done, then confirm with GH auth status. The code expires after 15 minutes. If it expires, stop the background command and start this bullet again.
- Get my GitHub username with: GH api user --jq .login
  Get my private GitHub email with: GH api user --jq '"\(.id)+\(.login)@users.noreply.github.com"'

Step 4: Get my course repo.
The course folder on this computer is claude-code-for-pms-final in my home folder. My repo on GitHub is <my username>/claude-code-for-pms-final.
- If the course folder already exists, is a git repo, and its origin is my GitHub repo, skip to step 5.
- If the course folder exists but is something else, rename it to claude-code-for-pms-final-old first.
- If my repo already exists on GitHub (check with GH repo view <my username>/claude-code-for-pms-final), clone it into the course folder.
- Otherwise, from my home folder, create it from the course template and clone it:
    GH repo create claude-code-for-pms-final --template Product-School-Platform/claude-code-for-pms-template --public --clone
  If the repo gets created but the clone fails, wait 10 seconds (GitHub can take a moment to finish copying the template) and clone it into the course folder.

Step 5: Connect this folder to my GitHub sign-in.
Inside the course folder only (never change git's settings for the rest of my computer):
- Set git user.name to my GitHub username and user.email to my private GitHub email from step 3. This keeps my personal email address off my work.
- Set this folder's own git setting so it saves to GitHub using the GitHub tool's sign-in: in the course folder's local git config, replace any existing credential.https://github.com.helper entries with exactly two, in this order: an empty entry (which clears any other sign-in method for this folder only), then one that runs GH with "auth git-credential". Use GH's full path in quotes, written the way git's shell on this computer understands it. Running this again must leave exactly those two entries.
- Check it works without saving anything: GIT_TERMINAL_PROMPT=0 git ls-remote origin should succeed.

Step 6: Finish.
Show me this checklist, with a check mark or an X on each line:
- Git works
- GitHub tool installed
- Signed in to GitHub as <my username>
- This folder saves to GitHub using that sign-in (nothing else on my computer was changed)
- My repo on GitHub: https://github.com/<my username>/claude-code-for-pms-final
- My course folder on this computer: <its full path, written the way my computer shows paths>
If anything has an X, tell me what to post in my course Slack channel, as described in the rules.
If everything has a check mark, tell me word for word: "One step left. In the Claude app, go to the Code tab, click + New session, choose <full path of my course folder> as the Project folder, and type: check my setup. If Claude asks whether you trust this folder, or whether to allow the rook-wiki and rook-database servers, say yes."
