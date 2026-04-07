# Build Your First AI Phone Agent: A Hands-On Workshop

> **Duration:** ~2 hours | **Level:** Beginner | **Languages:** Python, TypeScript, Ruby, Go, Perl, Java, C++, .NET, PHP
>
> By the end of this workshop, you'll have a live AI assistant on a real phone number that tells jokes, reports weather, knows the time, and does math -- all built by you from scratch.

---

## Section 1: Welcome and What We're Building (5 min)

Welcome to the SignalWire SDK workshop! Over the next two hours, you're going to build something that sounds complicated but is surprisingly approachable: **a voice AI agent that answers a real phone number**.

Here's what your finished agent will do:

- **Tell dad jokes** -- fresh ones from a live API, never the same joke twice
- **Report live weather** -- "What's the weather in Tokyo?" handled instantly, without your server lifting a finger
- **Tell time and date** -- any timezone, zero code required
- **Do math** -- "What's 15% tip on $47.50?" no problem
- **Sound natural** -- with a personality, smooth conversation flow, and filler phrases while it thinks

And you'll learn three different ways to give your agent capabilities:

1. **Custom functions** -- you write the handler, full control
2. **DataMap** -- declare an API call, SignalWire runs it serverlessly
3. **Skills** -- one line of code, instant capability

---

> [!TIP]
> ### Not a developer? No problem.
> **[Follow Along with the Non-Developer's Guide](https://workshop-replit-raleigh-2026.replit.app/)**
>
> We've gone ahead and built the agents for you. Just copy the [SWML](https://signalwire.com/docs/swml) Webhook URL and paste into your SignalWire dashboard and you're ready to talk to your agent -- no code, no setup headaches.

---

### Prerequisites

Before we start, make sure you have:

- [ ] **Docker Desktop** installed ([see setup below](#docker-desktop-recommended)), OR your **language runtime** installed natively
- [ ] **git** installed
- [ ] A **terminal** -- Terminal/iTerm2 on macOS, any terminal on Linux, or **Windows Terminal + WSL2** on Windows
- [ ] A **text editor** or IDE you're comfortable with
- [ ] A **web browser** for signing up for services
- [ ] A **phone** to call your agent when it's live

No prior experience with voice, telephony, or AI APIs is needed. If you can write a basic class in your chosen language, you're ready.

### How This Workshop Works

This workshop is split into two parts:

1. **Shared setup** (this README) -- covers platform setup, SignalWire account creation, API keys, and ngrok. Every language needs this.
2. **Language-specific guide** -- covers project setup, coding, testing, and deployment for your chosen language.

Each section builds on the last. You'll write code, test it, and hit a checkpoint before moving on. If something isn't working at a checkpoint, stop and troubleshoot before continuing -- every section depends on the one before it.

Let's get started.

---

## Platform Setup Guide

**Using Docker? That's the recommended path.** Jump straight to the [Docker Desktop](#docker-desktop-recommended) section below -- everything is pre-built, no language installation needed. Just run the container and `./config.sh`.

The native installation sections (macOS, Linux, Windows) are only needed if you prefer to install language runtimes directly on your machine.

### Supported Language Versions

| Language | Minimum Version | Recommended |
|----------|----------------|-------------|
| Python | 3.10+ | 3.12 |
| Node.js (TypeScript) | 18+ | 20 LTS |
| Go | 1.22+ | 1.23 |
| Ruby | 3.0+ | 3.3 |
| Perl | 5.20+ | 5.38 |
| Java | 21+ | 21 LTS |
| C++ | C++17 compiler | GCC 12+ or Clang 15+ |
| .NET (C#) | 8.0+ | 8.0 LTS |
| PHP | 8.1+ | 8.3 |

You only need the runtime(s) for the language(s) you plan to use. Most people pick one or two.

---

### Docker Desktop (Recommended)

The workshop image has **everything pre-built inside** -- all 9 language runtimes, all 9 SDKs compiled, venvs ready, ngrok installed. No cloning repos, no installing compilers, no version conflicts. Install Docker, run one command, and you're in.

---

#### Step 1: Install Docker Desktop

<details open>
<summary><strong>macOS</strong></summary>

1. Download **Docker Desktop** from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) or run:
   ```bash
   brew install --cask docker
   ```
2. Launch **Docker Desktop** from Applications
3. Wait for the whale icon in your menu bar to stop animating (engine is ready)
4. Open **Terminal** and continue to Step 2

</details>

<details>
<summary><strong>Windows</strong></summary>

1. **Install WSL2** -- open **PowerShell as Administrator** and run:
   ```powershell
   wsl --install
   ```
   Restart your computer when prompted. After reboot, a terminal opens -- create a username and password when asked.

2. **Install Docker Desktop** -- download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
   - During installation, ensure **"Use WSL 2 instead of Hyper-V"** is checked
   - Launch Docker Desktop after installing -- it configures WSL integration automatically

3. **Open a terminal** -- open **PowerShell** or **Windows Terminal** and continue to Step 2

> **Note:** You do NOT need to type `wsl` or use a Linux terminal. Docker runs from PowerShell directly. The `docker run` command below gives you a Linux shell inside the container.

</details>

<details>
<summary><strong>Linux (Ubuntu / Debian)</strong></summary>

```bash
# Add Docker's official repository
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Allow your user to run Docker without sudo
sudo usermod -aG docker $USER
```

**Log out and back in** for the group change to take effect, then continue to Step 2.

Or install [Docker Desktop for Linux](https://docs.docker.com/desktop/install/linux-install/) if you prefer the GUI.

</details>

---

#### Step 2: Start the Workshop

Open your terminal (Terminal on Mac, PowerShell on Windows, any terminal on Linux) and run:

```bash
docker login
docker run -it -p 3000:3000 -p 4040:4040 briankwest/workshop
```

> **`docker login`** — you may be prompted to log in to Docker Hub (free account at [hub.docker.com](https://hub.docker.com)). You only need to do this once.

This pulls the image (first time only) and drops you into the workshop. Type `workshop` to see everything available.

The two port flags make the workshop accessible from your computer:
- **Port 3000** -- your agent (so ngrok can reach it)
- **Port 4040** -- ngrok's web UI (open `http://localhost:4040` in your browser to inspect traffic)

> **What's pre-installed:** Python 3.12, Node.js 20, Go 1.23, Ruby 3.2, Perl 5.38, Java 21, C++ (g++ 13), .NET 8.0, PHP 8.3, ngrok, nano, vim -- plus all 9 SignalWire SDKs compiled and ready.

---

#### Step 3: Configure Your Credentials

Inside the container, run:

```bash
./config.sh
```

It walks you through four things:

1. **SignalWire** -- Project ID, API Token, Space Name (from [signalwire.com](https://signalwire.com) dashboard)
2. **Agent auth** -- username and password (auto-generated if you press Enter)
3. **ngrok** -- auth token and static domain (from [ngrok.com](https://ngrok.com) dashboard) -- starts the tunnel automatically
4. **API keys** -- WeatherAPI key (from [weatherapi.com](https://www.weatherapi.com)) and API Ninjas key (from [api-ninjas.com](https://api-ninjas.com)) -- needed for the weather and joke steps

When it finishes, it prints the **SWML URL** to paste into the SignalWire dashboard -- that connects your phone number to your agent.

---

#### Step 4: Run Your Agent

```bash
cd python
source venv/bin/activate
python steps/step04_hello_agent.py
```

Your agent is live on port 3000. ngrok is tunneling it to the internet. Call your phone number.

---

#### How It All Connects

```
Your Phone ──→ SignalWire Cloud ──→ ngrok tunnel ──→ Container :3000
                                                        ↑
                                        Your agent code runs here
```

Everything runs inside the container. ngrok creates an outbound tunnel from inside the container to ngrok's servers. SignalWire reaches your agent through that tunnel. Ports 3000 and 4040 are mapped to your host machine so the tunnel works regardless of whether you're on Mac, Windows, or Linux.

---

#### Quick Reference

| What | Command |
|------|---------|
| Start the workshop | `docker run -it -p 3000:3000 -p 4040:4040 briankwest/workshop` |
| Show help | `workshop` |
| Configure credentials | `./config.sh` |
| View ngrok tunnel | `screen -r workshop-ngrok` (detach: Ctrl-A D) |
| Stop ngrok | `screen -S workshop-ngrok -X quit` |
| ngrok web UI | `http://localhost:4040` in your browser |
| Edit credentials | `nano .env` |
| Re-enter container | Start a new one with the same `docker run` command above |

> **Note:** Each `docker run` starts a fresh container. Your `.env` credentials will need to be re-entered. This is by design for a workshop -- no state to debug.

> **If you're using Docker, skip ahead to [Section 2: SignalWire Account Setup](#section-2-signalwire-account-setup-10-min).** The macOS, Linux, and Windows sections below are only needed for native installation.

---

### Native Installation (Alternative)

If you prefer to install language runtimes directly on your machine instead of using Docker, follow the section for your platform below.

### macOS

#### 1. Install Xcode Command Line Tools

```bash
xcode-select --install
```

These provide `git`, `make`, `clang`, and other essentials.

#### 2. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installing, follow the instructions it prints to add Homebrew to your PATH.

#### 3. Clone and Run Setup

```bash
git clone https://github.com/signalwire-demos/workshop.git workshop
cd workshop
./setup.sh python go
```

Pass the languages you want, or run `./setup.sh` with no arguments for all of them. `setup.sh` detects missing dependencies and offers to `brew install` them for you.

> **Java PATH note:** If using Java, Homebrew's OpenJDK isn't on the system PATH by default. The `setup.sh` and `test.sh` scripts auto-detect it, but if you want it available everywhere, add to `~/.zshrc`:
> ```bash
> export JAVA_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"
> export PATH="$JAVA_HOME/bin:$PATH"
> ```

---

### Linux (Ubuntu / Debian)

These instructions target Ubuntu 22.04+ and Debian 12+, which are also the most common WSL distributions.

```bash
sudo apt update
git clone https://github.com/signalwire-demos/workshop.git workshop
cd workshop
./setup.sh python go
```

Pass the languages you want, or run `./setup.sh` with no arguments for all of them. `setup.sh` detects missing dependencies and offers to `apt install` them for you. For Go and Node.js, it installs from official sources (Go tarball, NodeSource PPA) since the default apt versions are often too old.

> **Note on port utilities:** Some minimal Linux installs don't include `lsof`. The workshop scripts automatically fall back to `ss` (included in all modern Linux distributions) for port detection, so this is handled for you.

---

### Windows (WSL2)

Windows users must use **Windows Subsystem for Linux (WSL2)** -- the workshop scripts are bash and won't run in PowerShell or CMD. WSL2 runs a real Linux kernel and has near-native performance.

#### 1. Install WSL2

Open **PowerShell as Administrator**:

```powershell
wsl --install Ubuntu-24.04
```

Restart your computer when prompted. After restarting, create a username and password when the Ubuntu terminal opens.

> **Already have WSL?** Check with `wsl -l -v`. If VERSION shows `1`, upgrade: `wsl --set-version Ubuntu-24.04 2`

#### 2. Clone and Run Setup (inside WSL)

> **Important:** Always clone into your WSL home directory (`~`), NOT `/mnt/c/...`. The Windows filesystem causes permission errors and is 5-10x slower.

```bash
cd ~
sudo apt update
git clone https://github.com/signalwire-demos/workshop.git workshop
cd workshop
./setup.sh python go
```

Pass the languages you want, or run `./setup.sh` with no arguments for all of them. `setup.sh` detects missing dependencies (including base tools like `git`, `curl`, `jq`, `build-essential`) and offers to install them. It also checks for CRLF line endings and `/mnt/c/` paths automatically.

#### WSL Tips

- **Networking:** Ports in WSL are accessible from Windows -- `localhost:3000` works in your browser
- **Editing:** Run `code .` from the workshop directory to open VS Code with the WSL extension. Don't use Windows Notepad or other editors that save with CRLF.
- **ngrok:** Install ngrok inside WSL (not on Windows) -- see Section 4
- **File access:** If localhost doesn't work (rare, some older WSL2 builds), try the WSL IP: `ip addr show eth0 | grep inet`

---

<details>
<summary><strong>Manual dependency install commands</strong> (if you prefer not to use the automated installer)</summary>

#### macOS (Homebrew)

```bash
# Base
brew install jq

# Pick your language(s):
brew install python@3.12         # Python
brew install node@20             # TypeScript
brew install go                  # Go
brew install ruby                # Ruby
brew install perl cpanminus      # Perl
brew install openjdk@21          # Java
brew install cmake               # C++
brew install dotnet@8            # .NET (C#)
brew install php composer        # PHP
```

#### Linux / WSL (apt)

```bash
# Base
sudo apt install -y git curl wget jq build-essential

# Pick your language(s):
sudo apt install -y python3 python3-venv python3-pip             # Python
sudo apt install -y ruby-full && sudo gem install bundler        # Ruby
sudo apt install -y perl cpanminus                               # Perl
sudo apt install -y openjdk-21-jdk                               # Java
sudo apt install -y cmake g++ libcurl4-openssl-dev nlohmann-json3-dev  # C++
sudo apt install -y php-cli php-mbstring php-xml php-curl             # PHP
```

**.NET (Linux):** Add the Microsoft repository, then install:

```bash
wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb && rm /tmp/packages-microsoft-prod.deb
sudo apt update && sudo apt install -y dotnet-sdk-8.0
```

**Composer (Linux):** Install PHP's package manager:

```bash
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
```

**Node.js (Linux):** The default apt package is often too old. Use NodeSource:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

**Go (Linux):** The apt version is usually too old. Install from the official tarball:

```bash
GO_VERSION=1.26.1
GO_ARCH=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
wget "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
rm "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

</details>

---

### What `setup.sh` Does

The `setup.sh` script automates the entire SDK setup process. Here's what it does for each language:

| Step | What Happens |
|------|-------------|
| **Dependencies** | Detects platform (macOS/Linux), checks for missing tools and runtimes, offers to install them |
| **Environment** | Creates `.env` from your inputs (API keys, credentials) and symlinks it into each language directory |
| **Clone SDKs** | Shallow-clones each SDK repo into `sdks/` |
| **Python** | Creates a venv, installs the SDK in editable mode |
| **TypeScript** | Runs `npm install` and `npm run build` for the SDK, then `npm install` in the workshop dir |
| **Go** | Runs `go mod tidy` (the SDK is linked via `go.mod` replace directive) |
| **Ruby** | Runs `bundle install` (the SDK is linked via Gemfile path directive) |
| **Perl** | Installs cpanm if missing, installs deps to the SDK's `local/` directory, symlinks `perl/lib` to the SDK |
| **Java** | Auto-detects Java 21 (Homebrew on macOS, `/usr/lib/jvm` on Linux, `JAVA_HOME`, or system default), builds the SDK jar with Gradle, copies it to `java/libs/` |
| **C++** | Builds the SDK static library with CMake |
| **.NET** | Builds the SDK with `dotnet build` |
| **PHP** | Runs `composer install` for the SDK |

You can run it for all languages or just the ones you need:

```bash
./setup.sh
./setup.sh python typescript
./setup.sh java
```

If you hit a problem with one language, fix it and re-run `setup.sh` for just that language -- it's safe to run multiple times.

---

### Running Tests

After setup, verify everything works:

```bash
./test.sh
./test.sh python
./test.sh python typescript
STEPS="04 06" ./test.sh go
```

The test script uses `swaig-test` (a CLI tool bundled with each SDK) to validate your agents produce correct SWML output and expose the right functions. File-based languages (Python, TypeScript) are tested without a server; URL-based languages (Go, Ruby, Perl, Java, C++) start the agent, test it over HTTP, and shut it down.

---

### Platform-Specific Troubleshooting

| Problem | Platform | Solution |
|---------|----------|----------|
| `command not found: brew` | macOS | Install Homebrew (see above), then restart your terminal |
| `python3: command not found` | Linux/WSL | `sudo apt install python3 python3-venv python3-pip` |
| `ensurepip is not available` (venv creation fails) | Linux/WSL | `sudo apt install python3.XX-venv` — replace `XX` with your Python minor version (e.g. `python3.12-venv`) |
| `chmod on .git/config.lock failed: Operation not permitted` | WSL | You cloned onto `/mnt/c/`. Delete it and re-clone into `~` (see WSL section above) |
| `node: command not found` after installing | Linux/WSL | If using nvm, run `source ~/.bashrc`; if using NodeSource, check `/usr/bin/node` exists |
| `go: command not found` after installing | Linux/WSL | Add `export PATH="/usr/local/go/bin:$PATH"` to `~/.bashrc` and `source ~/.bashrc` |
| `cannot execute binary file: Exec format error` (Go) | Linux/WSL | Wrong architecture — you installed amd64 on arm64 or vice versa. Re-install using the auto-detect commands in the Go section above |
| `Could not find gem 'dotenv'` (Ruby) | Linux/WSL | Run `./setup.sh ruby` — bundler hasn't installed gems yet |
| Java version too old | Linux/WSL | `sudo apt install openjdk-21-jdk` or use Adoptium (see above); `setup.sh` scans `/usr/lib/jvm` automatically |
| Java version too old | macOS | `brew install openjdk@21`; `setup.sh` auto-detects brew OpenJDK |
| `/bin/bash^M: bad interpreter` | WSL | Line ending issue. Run `dos2unix setup.sh test.sh` or re-clone from inside WSL |
| Port 3000 already in use | All | `test.sh` handles this automatically. Manual fix: `lsof -ti :3000 \| xargs kill` (macOS) or `ss -tlnp sport = :3000` to find the PID (Linux) |
| `lsof: command not found` | Linux/WSL | Not a problem -- the scripts fall back to `ss` automatically |
| `cmake: command not found` | Linux/WSL | `sudo apt install cmake` |
| `gradle: command not found` | Linux/WSL | Use SDKMAN (`sdk install gradle`) or let `setup.sh` use the bundled `gradlew` wrapper |
| Slow `npm install` or `go mod tidy` | WSL | Make sure you cloned inside WSL's filesystem (`~/workshop`), not on `/mnt/c/` |
| `localhost:3000` not reachable from Windows | WSL | Try `curl localhost:3000` from inside WSL first. If that works but the Windows browser can't reach it, check your WSL version (`wsl -l -v` should show VERSION 2) |
| Permission denied running `setup.sh` | All | `chmod +x setup.sh test.sh` |
| `docker compose` not found | All | Make sure Docker Desktop is running. On older installs, try `docker-compose` (with hyphen) |
| `docker compose build` fails | All | Check that Docker Desktop is running (whale icon in menu/system tray). On Linux, verify your user is in the `docker` group |
| Port 3000 not reachable from host | Docker | Make sure you used `--service-ports` flag: `docker compose run --rm --service-ports workshop bash` |
| Agent can't detect ngrok in Docker | Docker | Expected -- set `SWML_PROXY_URL_BASE=https://your-domain.ngrok-free.app` in `.env` |

---

## Section 2: SignalWire Account Setup (10 min)

SignalWire is the platform that connects your AI agent to the phone network. Their SDK is what we'll use to build our agent, and their cloud handles all the telephony, speech-to-text, text-to-speech, and AI orchestration.

### Step 1: Create a SignalWire Account

1. Go to [signalwire.com](https://signalwire.com) and click **Sign Up** or **Get Started**
2. Fill in your details and create an account
3. You'll receive trial credits -- that's plenty for this workshop

### Step 2: Get Your Credentials

Once you're logged in to the SignalWire Dashboard:

1. Your **Space Name** is in the URL: `https://YOUR-SPACE.signalwire.com` -- note it down
2. Click on **API** in the left sidebar
3. You'll see your **Project ID** -- copy it
4. Create a new **API Token** if one doesn't exist -- copy it

> **Keep these safe.** You'll need your Project ID, API Token, and Space Name in a few minutes.

### Step 3: Buy a Phone Number

1. In the dashboard, go to **Phone Numbers** > **Buy a Number**
2. Search for a number in your area code (or any area code you like)
3. Buy one number -- trial credits cover this

> **Don't configure the phone number yet.** We'll point it at your agent after we set up ngrok in Section 5. For now, just make sure you have a number purchased.

Write down your phone number. You'll need it later.

---

## Section 3: API Keys and ngrok Setup (10 min)

Your agent will use two external APIs: one for weather data and one for jokes. Both have generous free tiers. You'll also need ngrok to expose your local agent to the internet.

### Step 1: WeatherAPI Key

1. Go to [weatherapi.com](https://www.weatherapi.com/) and sign up for a free account
2. After signing in, your API key is shown on the dashboard
3. Copy your API key

> **Free tier:** 1 million calls per month. More than enough.

### Step 2: API Ninjas Key

1. Go to [api-ninjas.com](https://api-ninjas.com/) and create a free account
2. Go to **My Account** to find your API key
3. Copy your API key

> **Free tier:** 10,000 calls per month. Plenty for development.

### Step 3: ngrok Account and Static Domain

1. Go to [ngrok.com](https://ngrok.com/) and sign up for a free account
2. From the ngrok dashboard, copy your **Authtoken**
3. Go to **Domains** in the left sidebar and create a free static domain
   - It will look something like `your-name-here.ngrok-free.app`
   - Write this down -- it's your permanent tunnel URL

> **Why a static domain?** Without one, ngrok gives you a random URL every time you restart. A static domain means your SignalWire phone number configuration won't break between sessions.

### Step 4: Create Your Environment File

> **Docker users:** Skip this step. `./config.sh` inside the container creates your `.env` file interactively. Jump to [Section 4](#section-4-ngrok-setup-and-going-live) to understand how ngrok works, or go straight to your [language-specific guide](#choose-your-language).

Copy the `.env.example` file from the workshop root into your project directory and fill in your values:

```
# SignalWire Credentials
SIGNALWIRE_PROJECT_ID=your-project-id-here
SIGNALWIRE_API_TOKEN=your-api-token-here
SIGNALWIRE_SPACE=your-space.signalwire.com

# Agent Authentication
SWML_BASIC_AUTH_USER=workshop
SWML_BASIC_AUTH_PASSWORD=pickASecurePassword123

# Weather API
WEATHER_API_KEY=your-weatherapi-key-here

# API Ninjas
API_NINJAS_KEY=your-api-ninjas-key-here
```

Replace every placeholder with your actual values. See [`.env.example`](.env.example) for the full template.

> **Note:** You might notice there's no `SWML_PROXY_URL_BASE` here. The agent code will auto-detect your ngrok tunnel at startup -- no need to configure it manually. If you're not using ngrok (e.g., deploying to a cloud server), you can add `SWML_PROXY_URL_BASE=https://your-server.example.com` to this file as a fallback.

> **Important:** The `SWML_BASIC_AUTH_USER` and `SWML_BASIC_AUTH_PASSWORD` are credentials that SignalWire will use to authenticate with your agent. Choose whatever you want, but remember them -- you'll enter them into the SignalWire dashboard later.

---

## Section 4: ngrok Setup and Going Live

> **Docker users:** `./config.sh` handles ngrok automatically -- it configures your auth token, starts the tunnel in the background, and prints your SWML URL. You can skip to [Choose Your Language](#choose-your-language). The steps below are for native installation only.

Your agent will run locally, but SignalWire's cloud can't reach `localhost`. We need ngrok to create a public tunnel.

### Step 1: Install ngrok

**macOS:**
```bash
brew install ngrok
```

**Linux / WSL:**
```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update && sudo apt install ngrok
```

> **Windows users:** Install ngrok inside your WSL terminal using the Linux command above — not with `choco` or the Windows installer. Your agent runs in WSL, so ngrok needs to be there too.

Or download directly from [ngrok.com/download](https://ngrok.com/download).

### Step 2: Add Your Auth Token

> **Docker users:** `./config.sh` already handled this. Skip to [Step 4: Connect Your Phone Number](#step-4-connect-your-phone-number-after-your-agent-is-running).

```bash
ngrok config add-authtoken YOUR_NGROK_AUTHTOKEN
```

### Step 3: Start the Tunnel

> **Docker users:** `./config.sh` starts ngrok automatically in a background `screen` session. Skip to Step 4.

For native installation, start ngrok manually:

```bash
ngrok http --url=your-domain.ngrok-free.app 3000
```

Replace `your-domain.ngrok-free.app` with the static domain you created in Section 3.

You should see ngrok's status display showing your tunnel is active, forwarding from your static domain to `localhost:3000`.

> **Leave ngrok running.** Open a new terminal for everything else.

### Step 4: Connect Your Phone Number (After Your Agent Is Running)

Once your agent is running (you'll do this in the language-specific guide), go to the SignalWire Dashboard:

1. Go to **Phone Numbers**
2. Click on the number you purchased
3. Select **Edit Settings**
4. Click **Select Resource**, then  **+ add**
5. Create a new **Script**, we will be using a **SWML Script**
6. Under **Handle Calls Using**, select **External URL**
7. Enter your ngrok URL: `https://workshop:password123@your-domain.ngrok-free.app/`
8. Click **Save**

> **Don't forget the trailing slash** on the URL. Your agent is serving on `/`.

---

## Choose Your Language

You've completed the shared setup. Now pick your language and follow the language-specific guide to build your agent:

| Language | Guide | SDK |
|----------|-------|-----|
| **Python** | [python/README.md](python/README.md) | `signalwire` (PyPI) |
| **TypeScript** | [typescript/README.md](typescript/README.md) | `@signalwire/sdk` (npm) |
| **Ruby** | [ruby/README.md](ruby/README.md) | `signalwire` (RubyGems) |
| **Go** | [go/README.md](go/README.md) | `github.com/signalwire/signalwire-go` |
| **Perl** | [perl/README.md](perl/README.md) | `SignalWire` (CPAN) |
| **Java** | [java/README.md](java/README.md) | `com.signalwire:signalwire-sdk` (Maven) |
| **C++** | [cpp/README.md](cpp/README.md) | `signalwire-cpp` |
| **.NET (C#)** | [dotnet/README.md](dotnet/README.md) | `SignalWire.Sdk` (NuGet) |
| **PHP** | [php/README.md](php/README.md) | `signalwire/sdk` (Composer) |

Each language-specific guide covers:

- **Project setup** -- dependencies, project structure, build configuration
- **Hello World agent** -- your first agent, proving everything works
- **SWAIG functions** -- custom tool handlers
- **DataMap** -- serverless API calls
- **Skills** -- one-line capabilities
- **The complete agent** -- everything polished and put together
- **Testing** -- verifying each step before moving on

Step files are provided as checkpoints in each language directory's `steps/` folder, so you can compare your code at any point.

---

## Key Concepts

Before you dive into your language-specific guide, here are the core concepts you'll encounter. These work the same way across every language -- only the syntax changes.

### What Are SWAIG Functions?

SWAIG (SignalWire AI Gateway) functions are tools that the AI can decide to call during a conversation. When a caller says "tell me a joke," the AI recognizes it should call your `tell_joke` function, your handler code runs, and the result is spoken back to the caller.

It works like this:

1. Caller says something
2. AI decides which function (if any) to call
3. Your handler runs and returns a result
4. AI uses the result in its response

You define the function with a name, description (so the AI knows when to use it), parameters (what info the AI should extract from the conversation), and a handler (your code).

### What Is DataMap?

DataMap lets you declare an API call -- URL, parameters, response template -- and **SignalWire executes it on their infrastructure**. Your server never handles the request. It's faster (no round-trip to your server), and it works even if your server goes down.

Think of it this way:

- **Custom function** = "When the AI needs weather, send a request to my server, I'll call the weather API and return the result"
- **DataMap** = "When the AI needs weather, here's the weather API URL and how to format the response -- you do it, SignalWire"

### What Are Skills?

Skills are pre-built capabilities that ship with the SDK. Adding one is a single function call -- no handler to write, no API to call, no DataMap to configure. The SDK does everything.

### Three Ways to Add Capabilities

| Capability | Approach | Your Server Handles It? | When to Use |
|-----------|----------|------------------------|-------------|
| Dad Jokes | Custom function | Yes | Custom logic, database access, complex processing |
| Weather | DataMap | No (SignalWire) | REST API calls, no server code needed |
| DateTime | Skill | No (built-in) | When a pre-built skill exists for what you need |
| Math | Skill | No (built-in) | Fastest path, zero maintenance |

---

## Cross-Language API Reference

The SignalWire SDK is available in all nine languages. The concepts are identical -- only the syntax differs. Here's a side-by-side comparison of the core API calls:

### Creating an Agent

| Language | Syntax |
|----------|--------|
| Python | `AgentBase(name="...")` |
| TypeScript | `new AgentBase({name: "..."})` |
| Ruby | `AgentBase.new(name: "...")` |
| Go | `agent.NewAgentBase(agent.WithName("..."))` |
| Perl | `AgentBase->new(name => "...")` |
| Java | `AgentBase.builder().name("...").build()` |
| C++ | `AgentBase("name", "/route")` |
| .NET (C#) | `new AgentBase(new AgentOptions { Name = "..." })` |
| PHP | `new AgentBase(name: "...")` |

### Adding a Prompt Section

| Language | Syntax |
|----------|--------|
| Python | `prompt_add_section("Title", "body")` |
| TypeScript | `promptAddSection("Title", "body")` |
| Ruby | `prompt_add_section("Title", "body")` |
| Go | `PromptAddSection("Title", "body")` |
| Perl | `prompt_add_section("Title", "body")` |
| Java | `promptAddSection("Title", "body")` |
| C++ | `prompt_add_section("Title", "body")` |
| .NET (C#) | `PromptAddSection("Title", "body")` |
| PHP | `$agent->promptAddSection("Title", "body")` |

### Defining a Tool (Custom Function)

| Language | Syntax |
|----------|--------|
| Python | `define_tool(name, desc, params, handler)` |
| TypeScript | `defineTool(name, desc, params, handler)` |
| Ruby | `define_tool(name:, description:, ...)` |
| Go | `DefineTool(name, desc, params, handler)` |
| Perl | `define_tool(name =>, ...)` |
| Java | `defineTool(name, desc, params, handler)` |
| C++ | `define_tool(name, desc, params, handler)` |
| .NET (C#) | `DefineTool(name, desc, params, handler)` |
| PHP | `$agent->defineTool(name, desc, params, handler)` |

### Adding a Skill

| Language | Syntax |
|----------|--------|
| Python | `add_skill("datetime")` |
| TypeScript | `addSkill("datetime")` |
| Ruby | `add_skill("datetime")` |
| Go | `AddSkill("datetime")` |
| Perl | `add_skill("datetime")` |
| Java | `addSkill("datetime")` |
| C++ | `add_skill("datetime")` |
| .NET (C#) | `AddSkill("datetime")` |
| PHP | `$agent->addSkill("datetime")` |

### Running the Agent

| Language | Syntax |
|----------|--------|
| Python | `agent.run()` |
| TypeScript | `agent.run()` |
| Ruby | `agent.run` |
| Go | `agent.Run()` |
| Perl | `$agent->run` |
| Java | `agent.run()` |
| C++ | `agent.run()` |
| .NET (C#) | `agent.Run()` |
| PHP | `$agent->run()` |

---

## Workshop Structure

Here's how the workshop files are organized:

```
workshop/
├── README.md              # This file -- shared setup and concepts
├── .env.example           # Environment variable template
├── Dockerfile             # Docker image with all language runtimes
├── docker-compose.yml     # One-command container startup
├── python/
│   ├── README.md          # Python-specific guide
│   └── steps/             # Checkpoint files for each section
├── typescript/
│   ├── README.md          # TypeScript-specific guide
│   └── steps/             # Checkpoint files for each section
├── ruby/
│   ├── README.md          # Ruby-specific guide
│   └── steps/             # Checkpoint files for each section
├── go/
│   ├── README.md          # Go-specific guide
│   └── steps/             # Checkpoint files for each section
├── perl/
│   ├── README.md          # Perl-specific guide
│   └── steps/             # Checkpoint files for each section
├── java/
│   ├── README.md          # Java-specific guide
│   └── steps/             # Checkpoint files for each section
├── cpp/
│   ├── README.md          # C++-specific guide
│   └── steps/             # Checkpoint files for each section
├── dotnet/
│   ├── README.md          # .NET (C#)-specific guide
│   └── steps/             # Checkpoint files for each section
└── php/
    ├── README.md          # PHP-specific guide
    └── steps/             # Checkpoint files for each section
```

---

## Section 12: Where to Go From Here

Once you've completed the language-specific guide and your agent is working, here's what's possible next.

### What You've Learned

- **AgentBase** -- the foundation for every agent
- **Prompts** -- structured personality and instructions
- **Custom functions** -- handler functions the AI can call
- **DataMap** -- serverless API calls that run on SignalWire's infrastructure
- **Skills** -- pre-built capabilities, one line each
- **AI parameters** -- tuning conversation flow and behavior
- **Speech hints and fillers** -- making conversations sound natural
- **ngrok auto-detection** -- querying the local ngrok API to streamline development
- **Post-prompt and summaries** -- saving call data for debugging with the Post-Prompt Viewer

### What's Possible Next

The agent you built today is a starting point. Here's a taste of what the SDK can do:

**Contexts and Workflows** -- guide conversations through structured steps. Imagine an appointment scheduler that walks through date, time, service type, and confirmation -- each step with its own prompt and available functions.

**State Management** -- track information across the call with global data. Remember the caller's name, build up an order, track verification status.

**Prefab Agents** -- pre-built agent types designed for specific use cases, like collecting structured data from callers with built-in validation and retry logic.

**Multi-Agent Servers** -- run multiple agents on different routes from one server. A sales agent on `/sales`, support on `/support`, with SIP routing to direct calls.

**DataSphere and Vector Search** -- connect your agent to knowledge bases. Upload documents and your agent can search them to answer questions.

**Call Recording and Post-Call Processing** -- record calls, generate summaries, extract structured data after each call.

**Transfer and Conference** -- transfer callers to humans, join conference rooms, or hand off between AI agents.

### SDK Repositories

| Language | Repository |
|----------|-----------|
| Python | [github.com/signalwire/signalwire-python](https://github.com/signalwire/signalwire-python) |
| TypeScript | [github.com/signalwire/signalwire-typescript](https://github.com/signalwire/signalwire-typescript) |
| Ruby | [github.com/signalwire/signalwire-ruby](https://github.com/signalwire/signalwire-ruby) |
| Go | [github.com/signalwire/signalwire-go](https://github.com/signalwire/signalwire-go) |
| Perl | [github.com/signalwire/signalwire-perl](https://github.com/signalwire/signalwire-perl) |
| Java | [github.com/signalwire/signalwire-java](https://github.com/signalwire/signalwire-java) |
| C++ | [github.com/signalwire/signalwire-cpp](https://github.com/signalwire/signalwire-cpp) |
| .NET | [github.com/signalwire/signalwire-dotnet](https://github.com/signalwire/signalwire-dotnet) |
| PHP | [github.com/signalwire/signalwire-php](https://github.com/signalwire/signalwire-php) |

### Other Resources

- **SignalWire Documentation:** [developer.signalwire.com](https://developer.signalwire.com) -- platform docs, SWML reference, REST APIs
- **SignalWire Community:** [signalwire.community](https://signalwire.community) -- forums, Q&A, and community projects
- **Post-Prompt Viewer:** [postpromptviewer.signalwire.io](https://postpromptviewer.signalwire.io/) -- upload call JSON files to visualize and debug conversations

### Congratulations

You went from zero to a phone-callable AI assistant with four capabilities, built three different ways. You understand the core concepts of the SignalWire SDK, and you have a working codebase to experiment with.

The agent running on your laptop right now is the same technology powering production voice AI systems. The patterns you learned today -- custom functions, DataMap, skills, structured prompts -- scale from this workshop project to enterprise deployments.

Go build something great.

---

## Quick Reference

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `SWML_BASIC_AUTH_USER` | Username for agent authentication |
| `SWML_BASIC_AUTH_PASSWORD` | Password for agent authentication |
| `SWML_PROXY_URL_BASE` | Auto-detected from ngrok; set manually only if not using ngrok |
| `WEATHER_API_KEY` | WeatherAPI.com API key |
| `API_NINJAS_KEY` | API Ninjas API key |

### Troubleshooting (Shared)

| Problem | Solution |
|---------|----------|
| Can't reach agent from internet | Is ngrok running? Check `http://127.0.0.1:4040` |
| SignalWire can't reach agent | Verify SWML URL has trailing slash, auth matches |
| Weather returns errors | Check `WEATHER_API_KEY` in `.env` |
| Jokes return errors | Check `API_NINJAS_KEY` in `.env` |
| Agent doesn't call functions | Check function `description` -- AI needs clear guidance |
| Speech recognition is wrong | Add hints for commonly misheard words |
| Agent responds too fast | Increase `end_of_speech_timeout` in params |
| Agent goes silent | Decrease `attention_timeout` in params |
