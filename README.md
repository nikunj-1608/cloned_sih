# SIH26: Prismarine

Please read through this entire document carefully before setting up your local environment or writing any code.

## Project Documentation

To keep this repository organized, our documentation is split into specific files. Please refer to them below:

*   [Problem Statement (PS.md)](./PS.md): The official ISRO problem statement (SIH26176)
*   [Tasks & Delegation (Tasks.md)](./Tasks.md): Phase-wise breakdown of tasks and assigned team members
*   [Project State (PROJECT_STATE.md)](./PROJECT_STATE.md): Current progress, blockers, and completed milestones
*   [LLM Prompts (CLAUDE.md)](./CLAUDE.md): This file provides system context, tech stack details, and coding conventions for AI assistants (like Claude, Cursor, or Copilot) interacting with this repository. 

> [!NOTE]
> If there are any deviations from the plan, update it in the [Project State (PROJECT_STATE.md)](./PROJECT_STATE.md) and [Tasks list (Tasks.md)](./Tasks.md).

---

## 1. GitHub Access & Initial Setup

The repository is live at `git@github.com:realpratz/SIH26.git`.

You have all been added as collaborators. 
1. Check your email or visit [github.com/realpratz/SIH26/invitations](https://github.com/realpratz/SIH26/invitations) and click **Accept**.
2. If you do not accept the invite, your terminal will return a "Repository not found" error when you attempt to clone it.
3. Once accepted, clone the repository to your local machine.

---

## 2. Git Workflow

To prevent merge conflicts and broken code, we are following a strict Git workflow. The default branch is `staging`. Both `staging` and `main` are locked. 

> [!WARNING]
> **Do not write code directly on the `staging` branch.**

### Branching & Committing
*   When you clone the repository, create a new branch for your specific feature before making changes:
    ```bash
    git checkout -b type/feature-name
    ```
    *(Example: `git checkout -b feat/ui-login` or `git checkout -b fix/map-crash`)*
*   When you are done with your task, push your branch to GitHub and open a Pull Request (PR) against the `staging` branch.
*   I will review the code and merge it into staging once it passes checks.

> [!CAUTION]
> Do not fork. Only branch.

### Pull Request Headers
We use conventional commit messages for our PR headers. Without a proper header, your PR will not be merged.
*(Example: `feat: add login screen`, `fix: resolve api timeout`, `docs: update readme`)*
Read more on conventional PR headers here: [Conventional Commits Gist](https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716)

---

## 3. Environment Variables & API Keys

Whenever you deal with APIs, create a `.env.example`. **This is a dummy template. Never put real passwords or API keys in this file.**

Once it is set up, to set up your local environment, follow these exact steps:

1.  Create a brand new file on your laptop in the same directory and name it exactly `.env`
2.  Copy all the text from `.env.example` and paste it into your new `.env` file.
3.  Replace the placeholder values in your `.env` file with the actual API keys and database passwords.
4.  The `.env` file is heavily restricted and blocked from GitHub via our `.gitignore`. This ensures our real keys never get uploaded to the internet, preventing them from being stolen or banned.

> [!IMPORTANT]
> Whenever you generate new keys for a service we need, drop them in our team chat so the rest of us can update our local `.env` files.

---

If you have any doubts regarding the `.env` setup, API keys, or face any issues contact me directly.