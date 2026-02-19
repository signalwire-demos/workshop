# Build Your First AI Phone Agent: A Hands-On Workshop

> **Duration:** ~2 hours | **Level:** Beginner | **Language:** Python
>
> By the end of this workshop, you'll have a live AI assistant on a real phone number that tells jokes, reports weather, knows the time, and does math -- all built by you from scratch.

---

## Section 1: Welcome and What We're Building (5 min)

Welcome to the SignalWire AI Agents SDK workshop! Over the next two hours, you're going to build something that sounds complicated but is surprisingly approachable: **a voice AI agent that answers a real phone number**.

Here's what your finished agent will do:

- **Tell dad jokes** -- fresh ones from a live API, never the same joke twice
- **Report live weather** -- "What's the weather in Tokyo?" handled instantly, without your server lifting a finger
- **Tell time and date** -- any timezone, zero code required
- **Do math** -- "What's 15% tip on $47.50?" no problem
- **Sound natural** -- with a personality, smooth conversation flow, and filler phrases while it thinks

And you'll learn three different ways to give your agent capabilities:

1. **Custom functions** (`define_tool`) -- you write the Python, full control
2. **DataMap** -- declare an API call, SignalWire runs it serverlessly
3. **Skills** -- one line of code, instant capability

### Prerequisites

Before we start, make sure you have:

- [ ] **Python 3.9+** installed (`python3 --version` to check)
- [ ] A **terminal** (Terminal on Mac, Command Prompt or WSL on Windows)
- [ ] A **text editor** (VS Code, PyCharm, Sublime Text, or anything you're comfortable with)
- [ ] A **web browser** for signing up for services
- [ ] A **phone** to call your agent when it's live

No prior experience with voice, telephony, or AI APIs is needed. If you can write a basic Python class, you're ready.

### How This Workshop Works

Each section builds on the last. You'll write code, test it, and hit a checkpoint before moving on. If something isn't working at a checkpoint, stop and troubleshoot before continuing -- every section depends on the one before it.

Let's get started.

---

## Section 2: SignalWire Account Setup (10 min)

SignalWire is the platform that connects your AI agent to the phone network. Their AI Agents SDK is what we'll use to build our agent, and their cloud handles all the telephony, speech-to-text, text-to-speech, and AI orchestration.

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

## Section 3: API Keys and Project Setup (10 min)

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

### Step 4: Create Your Project Directory

Open a terminal and set up your project:

```bash
mkdir workshop-agent
cd workshop-agent
```

### Step 5: Create Your Environment File

Create a file called `.env` in your project directory with all your keys:

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

Replace every placeholder with your actual values.

> **Note:** You might notice there's no `SWML_PROXY_URL_BASE` here. Our agent code will auto-detect your ngrok tunnel at startup -- no need to configure it manually. If you're not using ngrok (e.g., deploying to a cloud server), you can add `SWML_PROXY_URL_BASE=https://your-server.example.com` to this file as a fallback.

> **Important:** The `SWML_BASIC_AUTH_USER` and `SWML_BASIC_AUTH_PASSWORD` are credentials that SignalWire will use to authenticate with your agent. Choose whatever you want, but remember them -- you'll enter them into the SignalWire dashboard later.

### Step 6: Create requirements.txt

Create a `requirements.txt` file:

```
signalwire-agents
python-dotenv
requests
```

Your project directory should now look like this:

```
workshop-agent/
├── .env
└── requirements.txt
```

---

## Section 4: Install and Hello World (10 min)

Time to write some code. We'll start with the simplest possible agent -- just enough to prove everything is wired up correctly.

### Step 1: Create a Virtual Environment and Install

```bash
python3 -m venv venv
source venv/bin/activate      # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

You should see `signalwire-agents`, `python-dotenv`, `requests`, and their dependencies install successfully.

### Step 2: Write Your First Agent

Create a file called `hello_agent.py`:

`hello_agent.py`

```python
#!/usr/bin/env python3
"""My first AI phone agent -- Hello World edition."""

import json
import os
from datetime import datetime
import requests
from dotenv import load_dotenv
load_dotenv()

def check_ngrok():
    """Auto-detect ngrok tunnel and set SWML_PROXY_URL_BASE."""
    try:
        resp = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=1)
        tunnels = resp.json().get("tunnels", [])
        for t in tunnels:
            if t.get("proto") == "https":
                url = t["public_url"]
                os.environ["SWML_PROXY_URL_BASE"] = url
                print(f"ngrok detected: {url}")
                return url
    except Exception:
        pass
    current = os.getenv("SWML_PROXY_URL_BASE", "")
    if current:
        print(f"Using SWML_PROXY_URL_BASE from .env: {current}")
    else:
        print("No ngrok tunnel detected and SWML_PROXY_URL_BASE not set")
    return current

check_ngrok()

from signalwire_agents import AgentBase

class HelloAgent(AgentBase):
    def __init__(self):
        super().__init__(name="hello-agent")

        # Set up the voice
        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well"]
        )

        # Tell the AI who it is
        self.prompt_add_section(
            "Role",
            "You are a friendly assistant named Buddy. "
            "You greet callers warmly, ask how their day is going, "
            "and have a brief pleasant conversation. "
            "Keep your responses short since this is a phone call."
        )

        # Post-prompt: summarize every call and save to calls/ folder
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Include what the caller wanted and how the conversation went."
        )

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging."""
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")

if __name__ == "__main__":
    agent = HelloAgent()
    agent.run()
```

Let's break down what's happening:

- `load_dotenv()` reads your `.env` file so environment variables are available
- `check_ngrok()` queries ngrok's local API at `http://127.0.0.1:4040` to discover the tunnel URL. If ngrok is running, it automatically sets `SWML_PROXY_URL_BASE` -- the environment variable the SDK uses to generate correct webhook URLs. If ngrok isn't running yet (it isn't -- we'll set it up in Section 5), it prints a helpful message and moves on. No manual URL configuration needed.
- `AgentBase` is the foundation class for every agent
- `add_language()` sets up English speech recognition, and `rime.spore` is a warm, friendly text-to-speech voice
- `prompt_add_section()` gives the AI its instructions
- `set_post_prompt()` tells the AI to generate a summary after every call. When the call ends, SignalWire sends the summary data to your agent's `/post_prompt` endpoint.
- `on_summary()` receives that data and saves the full JSON payload to a `calls/` folder. Each file is named by call ID. You can upload these files to [postpromptviewer.signalwire.io](https://postpromptviewer.signalwire.io/) to visualize and debug your agent's conversations.
- `agent.run()` starts a web server on port 3000

### Step 3: Test with swaig-test

Before we run the server, let's verify the agent's configuration is valid:

```bash
swaig-test hello_agent.py --dump-swml
```

You should see a JSON document -- this is the SWML (SignalWire Markup Language) that tells the SignalWire platform how to run your agent. Look for your prompt text in the output.

You can also test with curl. First, run the agent:

```bash
python hello_agent.py
```

You'll see output like:

```
No ngrok tunnel detected and SWML_PROXY_URL_BASE not set
INFO: SWML Basic Auth user: workshop
INFO: SWML Basic Auth password: pickASecurePassword123
INFO: Uvicorn running on http://0.0.0.0:3000
```

The "No ngrok tunnel detected" message is expected -- we haven't set up ngrok yet. That's coming in Section 5.

In a **separate terminal** (keep the agent running), test with curl:

```bash
curl -s -u workshop:pickASecurePassword123 http://localhost:3000/ | python3 -m json.tool
```

Use whatever values you set for `SWML_BASIC_AUTH_USER` and `SWML_BASIC_AUTH_PASSWORD` in your `.env` file.

You should see the same SWML JSON. Your agent is serving its configuration correctly.

> **Checkpoint:** You see SWML JSON output from both `swaig-test` and curl. The JSON contains your prompt text and voice settings. If not, double-check that your `.env` is loaded (is `load_dotenv()` before your imports?) and that your virtual environment is activated.

---

## Section 5: ngrok and Going Live (10 min)

Your agent is running locally, but SignalWire's cloud can't reach `localhost:3000`. We need ngrok to create a public tunnel.

### Step 1: Install ngrok

**macOS:**
```bash
brew install ngrok
```

**Linux:**
```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com ngrok main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update && sudo apt install ngrok
```

**Windows:**
```bash
choco install ngrok
```

Or download directly from [ngrok.com/download](https://ngrok.com/download).

### Step 2: Add Your Auth Token

```bash
ngrok config add-authtoken YOUR_NGROK_AUTHTOKEN
```

### Step 3: Start the Tunnel

In a new terminal (keep your agent running in the first one):

```bash
ngrok http --url=your-domain.ngrok-free.app 3000
```

Replace `your-domain.ngrok-free.app` with the static domain you created in Section 3.

You should see ngrok's status display showing your tunnel is active, forwarding from your static domain to `localhost:3000`.

### Step 4: Restart Your Agent

Now that ngrok is running, restart your agent (Ctrl+C the old one, then run it again):

```bash
python hello_agent.py
```

This time you should see:

```
ngrok detected: https://your-domain.ngrok-free.app
INFO: SWML Basic Auth user: workshop
INFO: Uvicorn running on http://0.0.0.0:3000
```

The `check_ngrok()` function we wrote earlier just found your tunnel automatically. No need to manually configure `SWML_PROXY_URL_BASE` -- the agent discovers it on every startup.

### Step 5: Test Through the Tunnel

From another terminal:

```bash
curl -s -u workshop:pickASecurePassword123 https://your-domain.ngrok-free.app/ | python3 -m json.tool
```

You should get the same SWML JSON, but now it's coming through the public internet. Look at the `web_hook_url` values in the JSON -- they should reference your ngrok domain, confirming the auto-detection worked.

### Step 6: Connect Your Phone Number

Now the exciting part. Go back to the SignalWire Dashboard:

1. Go to **Phone Numbers**
2. Click on the number you purchased
3. Under **Voice and Fax Settings**, set the handler to **SWML**
4. For **When a Call Comes In**, select **Use an external URL**
5. Enter your ngrok URL: `https://your-domain.ngrok-free.app/`
6. Click **Save**

> **Don't forget the trailing slash** on the URL. Your agent is serving on `/`.

### Step 7: Call Your Agent

Pick up your phone and call the number you purchased. You should hear the agent greet you!

It can't do much yet -- just have a friendly chat -- but you're talking to an AI agent running on your laptop. That's pretty great for 45 minutes of work.

> **Checkpoint:** You can call your phone number and have a conversation with your agent. It greets you warmly and chats. If the call fails, check: Is ngrok running? Is your agent running? Is the URL in SignalWire correct (with trailing slash)? Check the ngrok web interface at `http://127.0.0.1:4040` to see if requests are reaching your agent.

---

## Section 6: Your First SWAIG Function (15 min)

Your agent can talk, but it can't *do* anything. Let's fix that by teaching it to tell jokes.

### What Are SWAIG Functions?

SWAIG (SignalWire AI Gateway) functions are tools that the AI can decide to call during a conversation. When a caller says "tell me a joke," the AI recognizes it should call your `tell_joke` function, your Python code runs, and the result is spoken back to the caller.

It works like this:

1. Caller says something
2. AI decides which function (if any) to call
3. Your Python handler runs and returns a result
4. AI uses the result in its response

You define the function with a name, description (so the AI knows when to use it), parameters (what info the AI should extract from the conversation), and a handler (your Python code).

### Step 1: Create the Joke Agent

Create a new file called `joke_agent.py`:

`joke_agent.py`

```python
#!/usr/bin/env python3
"""Agent with a hardcoded joke function."""

import json
import os
import random
from datetime import datetime
import requests
from dotenv import load_dotenv
load_dotenv()

def check_ngrok():
    """Auto-detect ngrok tunnel and set SWML_PROXY_URL_BASE."""
    try:
        resp = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=1)
        tunnels = resp.json().get("tunnels", [])
        for t in tunnels:
            if t.get("proto") == "https":
                url = t["public_url"]
                os.environ["SWML_PROXY_URL_BASE"] = url
                print(f"ngrok detected: {url}")
                return url
    except Exception:
        pass
    current = os.getenv("SWML_PROXY_URL_BASE", "")
    if current:
        print(f"Using SWML_PROXY_URL_BASE from .env: {current}")
    else:
        print("No ngrok tunnel detected and SWML_PROXY_URL_BASE not set")
    return current

check_ngrok()

from signalwire_agents import AgentBase, SwaigFunctionResult

JOKES = [
    "Why do programmers prefer dark mode? Because light attracts bugs.",
    "I told my wife she was drawing her eyebrows too high. She looked surprised.",
    "What do you call a fake noodle? An impasta.",
    "Why don't scientists trust atoms? Because they make up everything.",
    "I'm reading a book about anti-gravity. It's impossible to put down.",
    "What did the ocean say to the beach? Nothing, it just waved.",
    "Why did the scarecrow win an award? He was outstanding in his field.",
    "I used to hate facial hair, but then it grew on me.",
]

class JokeAgent(AgentBase):
    def __init__(self):
        super().__init__(name="joke-agent")

        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well"],
            function_fillers=["Let me think of a good one..."]
        )

        self.prompt_add_section(
            "Role",
            "You are a friendly assistant named Buddy. "
            "You love telling jokes and making people laugh. "
            "Keep your responses short since this is a phone call."
        )

        self.prompt_add_section(
            "Guidelines",
            body="Follow these guidelines:",
            bullets=[
                "When someone asks for a joke, use the tell_joke function",
                "After telling a joke, pause for a reaction before offering another",
                "Be enthusiastic and have fun with it",
            ]
        )

        # Register the joke function
        self.define_tool(
            name="tell_joke",
            description="Tell the caller a funny joke. Use this whenever someone asks for a joke or humor.",
            parameters={"type": "object", "properties": {}},
            handler=self.on_tell_joke,
        )

        # Post-prompt: summarize every call and save to calls/ folder
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Note which jokes were told and how the caller reacted."
        )

    def on_tell_joke(self, args, raw_data):
        joke = random.choice(JOKES)
        return SwaigFunctionResult(f"Here's a joke: {joke}")

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging."""
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")

if __name__ == "__main__":
    agent = JokeAgent()
    agent.run()
```

Let's look at the new pieces:

- `SwaigFunctionResult` is how you return data from a SWAIG function. The AI takes this text and weaves it into its response.
- `define_tool()` registers the function. The `description` is critical -- it tells the AI *when* to call this function.
- `parameters` defines what the AI should extract from the conversation. Our joke function doesn't need any input, so it's an empty object.
- `function_fillers` are phrases the agent says while your function executes, so there's no awkward silence.

### Step 2: Test the Function

Stop your previous agent (Ctrl+C) and test the new one:

```bash
swaig-test joke_agent.py --list-tools
```

You should see `tell_joke` listed. Now test executing it:

```bash
swaig-test joke_agent.py --exec tell_joke
```

You should see a joke from the list. Run it a few times -- you'll get different jokes.

### Step 3: Run and Call

```bash
python joke_agent.py
```

With ngrok still running, call your number and ask for a joke. Try phrases like:
- "Tell me a joke"
- "Make me laugh"
- "Got any jokes?"

The AI should recognize these as requests for humor and call your function.

> **Checkpoint:** When you call and ask for a joke, the agent tells you one from the hardcoded list. You can see function calls in your agent's terminal output. If the agent talks about jokes but doesn't actually tell one from the list, check that your `define_tool` description clearly instructs the AI to use the function.

---

## Section 7: Calling a Live API (15 min)

Hardcoded jokes get old fast. Let's replace them with fresh dad jokes from the API Ninjas Dad Jokes API. Every call will be a different joke.

### Step 1: Understanding the API

The API Ninjas Dad Jokes endpoint is simple:

- **URL:** `https://api.api-ninjas.com/v1/dadjokes`
- **Method:** GET
- **Auth:** `X-Api-Key` header with your API key
- **Response:** A JSON array with a `joke` field: `[{"joke": "..."}]`

You can test it right now in your terminal:

```bash
curl -s -H "X-Api-Key: YOUR_API_NINJAS_KEY" https://api.api-ninjas.com/v1/dadjokes | python3 -m json.tool
```

### Step 2: Update the Joke Agent

Edit `joke_agent.py` -- we'll replace the hardcoded jokes with a live API call. Replace the entire file:

`joke_agent.py`

```python
#!/usr/bin/env python3
"""Agent that tells fresh dad jokes from API Ninjas."""

import json
import os
from datetime import datetime
import requests
from dotenv import load_dotenv
load_dotenv()

def check_ngrok():
    """Auto-detect ngrok tunnel and set SWML_PROXY_URL_BASE."""
    try:
        resp = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=1)
        tunnels = resp.json().get("tunnels", [])
        for t in tunnels:
            if t.get("proto") == "https":
                url = t["public_url"]
                os.environ["SWML_PROXY_URL_BASE"] = url
                print(f"ngrok detected: {url}")
                return url
    except Exception:
        pass
    current = os.getenv("SWML_PROXY_URL_BASE", "")
    if current:
        print(f"Using SWML_PROXY_URL_BASE from .env: {current}")
    else:
        print("No ngrok tunnel detected and SWML_PROXY_URL_BASE not set")
    return current

check_ngrok()

from signalwire_agents import AgentBase, SwaigFunctionResult

class JokeAgent(AgentBase):
    def __init__(self):
        super().__init__(name="joke-agent")

        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well"],
            function_fillers=["Let me think of a good one..."]
        )

        self.prompt_add_section(
            "Role",
            "You are a friendly assistant named Buddy. "
            "You love telling jokes and making people laugh. "
            "Keep your responses short since this is a phone call."
        )

        self.prompt_add_section(
            "Guidelines",
            body="Follow these guidelines:",
            bullets=[
                "When someone asks for a joke, use the tell_joke function",
                "After telling a joke, pause for a reaction before offering another",
                "Be enthusiastic and have fun with it",
            ]
        )

        self.define_tool(
            name="tell_joke",
            description="Tell the caller a funny dad joke. Use this whenever someone asks for a joke, humor, or to be entertained.",
            parameters={"type": "object", "properties": {}},
            handler=self.on_tell_joke,
        )

        # Post-prompt: summarize every call and save to calls/ folder
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Note which jokes were told and how the caller reacted."
        )

    def on_tell_joke(self, args, raw_data):
        api_key = os.getenv("API_NINJAS_KEY", "")
        if not api_key:
            return SwaigFunctionResult("Sorry, I can't access my joke book right now. My API key is missing.")

        try:
            resp = requests.get(
                "https://api.api-ninjas.com/v1/dadjokes",
                headers={"X-Api-Key": api_key},
                timeout=5,
            )
            resp.raise_for_status()
            jokes = resp.json()
            if jokes:
                return SwaigFunctionResult(f"Here's a dad joke: {jokes[0]['joke']}")
            return SwaigFunctionResult("I tried to find a joke but came up empty. That's... kind of a joke itself?")
        except requests.RequestException:
            return SwaigFunctionResult("Sorry, my joke service is taking a nap. Ask me again in a moment!")

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging."""
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")

if __name__ == "__main__":
    agent = JokeAgent()
    agent.run()
```

What changed:

- Removed the `JOKES` list and `random` import
- Added `os` and `requests` imports
- The handler now calls the API Ninjas endpoint
- We read the API key from the environment (your `.env` file)
- There's error handling -- if the API is down or the key is wrong, the agent says something graceful instead of crashing

### Step 3: Test It

```bash
swaig-test joke_agent.py --exec tell_joke
```

Run it several times. Every joke should be different. If you see an error about the API key, make sure `API_NINJAS_KEY` is set in your `.env` file.

### Step 4: Call and Test

Restart your agent:

```bash
python joke_agent.py
```

Call your number and ask for jokes. Every joke is now fresh from the internet.

> **Checkpoint:** Every time you ask for a joke, you get a different one. Running `swaig-test --exec tell_joke` multiple times confirms this. If you're getting the same joke every time, the API might be caching -- wait a moment and try again.

---

## Section 8: DataMap -- The Serverless Approach (15 min)

For the joke function, you wrote Python code that runs on your server. That works great, but there's another way: **DataMap**.

### What Is DataMap?

DataMap lets you declare an API call -- URL, parameters, response template -- and **SignalWire executes it on their infrastructure**. Your server never handles the request. It's faster (no round-trip to your server), and it works even if your server goes down.

Think of it this way:

- **define_tool** = "When the AI needs weather, send a request to my server, I'll call the weather API and return the result"
- **DataMap** = "When the AI needs weather, here's the weather API URL and how to format the response -- you do it, SignalWire"

### Step 1: Create the Weather + Joke Agent

Let's create a new agent that has both jokes (via your custom function) and weather (via DataMap). Create `weather_joke_agent.py`:

`weather_joke_agent.py`

```python
#!/usr/bin/env python3
"""Agent with dad jokes (custom function) and weather (DataMap)."""

import json
import os
from datetime import datetime
import requests
from dotenv import load_dotenv
load_dotenv()

def check_ngrok():
    """Auto-detect ngrok tunnel and set SWML_PROXY_URL_BASE."""
    try:
        resp = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=1)
        tunnels = resp.json().get("tunnels", [])
        for t in tunnels:
            if t.get("proto") == "https":
                url = t["public_url"]
                os.environ["SWML_PROXY_URL_BASE"] = url
                print(f"ngrok detected: {url}")
                return url
    except Exception:
        pass
    current = os.getenv("SWML_PROXY_URL_BASE", "")
    if current:
        print(f"Using SWML_PROXY_URL_BASE from .env: {current}")
    else:
        print("No ngrok tunnel detected and SWML_PROXY_URL_BASE not set")
    return current

check_ngrok()

from signalwire_agents import AgentBase, SwaigFunctionResult
from signalwire_agents.core.data_map import DataMap

class WeatherJokeAgent(AgentBase):
    def __init__(self):
        super().__init__(name="weather-joke-agent")

        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well"],
            function_fillers=[
                "Let me check on that...",
                "One moment...",
            ]
        )

        self.prompt_add_section(
            "Role",
            "You are a friendly assistant named Buddy. "
            "You help people with weather information and tell great jokes. "
            "Keep your responses short since this is a phone call."
        )

        self.prompt_add_section(
            "Guidelines",
            body="Follow these guidelines:",
            bullets=[
                "When someone asks about weather, use the get_weather function",
                "When someone asks for a joke, use the tell_joke function",
                "Be warm, friendly, and conversational",
            ]
        )

        self._register_joke_function()
        self._register_weather_datamap()

        # Post-prompt: summarize every call and save to calls/ folder
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Note what the caller asked about (weather, jokes, etc.) "
            "and how the interaction went."
        )

    def _register_joke_function(self):
        """Register the dad joke function (runs on our server)."""
        self.define_tool(
            name="tell_joke",
            description="Tell the caller a funny dad joke. Use this whenever someone asks for a joke or humor.",
            parameters={"type": "object", "properties": {}},
            handler=self.on_tell_joke,
            fillers={
                "en-US": ["Let me think of a good one..."],
            },
        )

    def on_tell_joke(self, args, raw_data):
        api_key = os.getenv("API_NINJAS_KEY", "")
        if not api_key:
            return SwaigFunctionResult("Sorry, my joke book is unavailable right now.")

        try:
            resp = requests.get(
                "https://api.api-ninjas.com/v1/dadjokes",
                headers={"X-Api-Key": api_key},
                timeout=5,
            )
            resp.raise_for_status()
            jokes = resp.json()
            if jokes:
                return SwaigFunctionResult(f"Here's a dad joke: {jokes[0]['joke']}")
            return SwaigFunctionResult("I couldn't find a joke this time. Try again!")
        except requests.RequestException:
            return SwaigFunctionResult("My joke service is taking a break. Try again in a moment!")

    def _register_weather_datamap(self):
        """Register weather lookup via DataMap (runs on SignalWire's servers)."""
        api_key = os.getenv("WEATHER_API_KEY", "")

        weather_dm = (
            DataMap("get_weather")
            .description(
                "Get the current weather for a city. "
                "Use this when the caller asks about weather, temperature, or conditions."
            )
            .parameter("city", "string", "The city to get weather for", required=True)
            .webhook(
                "GET",
                f"https://api.weatherapi.com/v1/current.json?key={api_key}&q=${{enc:args.city}}"
            )
            .output(SwaigFunctionResult(
                "Weather in ${args.city}: ${response.current.condition.text}, "
                "${response.current.temp_f} degrees Fahrenheit, "
                "humidity ${response.current.humidity} percent. "
                "Feels like ${response.current.feelslike_f} degrees."
            ))
            .fallback_output(SwaigFunctionResult(
                "Sorry, I couldn't get the weather for ${args.city}. "
                "Please check the city name and try again."
            ))
        )

        self.register_swaig_function(weather_dm.to_swaig_function())

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging."""
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")

if __name__ == "__main__":
    agent = WeatherJokeAgent()
    agent.run()
```

Let's unpack the DataMap piece:

- `DataMap("get_weather")` -- creates a new DataMap function with that name
- `.description(...)` -- tells the AI when to use it (same as `define_tool`)
- `.parameter("city", "string", ...)` -- the AI will extract the city from the caller's request
- `.webhook("GET", url)` -- the HTTP request SignalWire will make. Notice `${enc:args.city}` -- that's the city parameter, URL-encoded, inserted right into the URL
- `.output(...)` -- a template for the response. `${response.current.temp_f}` pulls the temperature from the API's JSON response
- `.fallback_output(...)` -- what to say if the API call fails

The API key is baked into the URL at startup time (via the f-string). The city gets substituted at call time (via `${enc:args.city}`).

### Step 2: Test It

```bash
swaig-test weather_joke_agent.py --list-tools
```

You should see both `tell_joke` and `get_weather`. Now look at how the DataMap appears in the SWML:

```bash
swaig-test weather_joke_agent.py --dump-swml
```

Find the `get_weather` function in the JSON. Notice it has a `data_map` section instead of a `web_hook_url` -- that tells SignalWire to execute the API call directly.

Test the joke function still works:

```bash
swaig-test weather_joke_agent.py --exec tell_joke
```

> **Note:** You can't test DataMap functions locally with `--exec` because they run on SignalWire's infrastructure, not your server. You'll test weather by calling your agent.

### Step 3: Call and Test

Stop any running agent and start the new one:

```bash
python weather_joke_agent.py
```

Call your number and try:
- "What's the weather in New York?"
- "How's the weather in London?"
- "Tell me a joke"
- "What's the temperature in Tokyo?"

You now have an agent with two capabilities, built two different ways.

> **Checkpoint:** Your agent answers weather questions with live data AND tells fresh dad jokes. The weather responses include temperature, conditions, and humidity. If weather isn't working, double-check your `WEATHER_API_KEY` in `.env` -- DataMap sends the key directly to WeatherAPI, so it must be correct.

---

## Section 9: Polish and Personality (10 min)

Your agent works, but it sounds a bit robotic. Let's give it a personality and tune the conversation flow. Same file, better experience.

### Step 1: Upgrade the Prompts

Edit `weather_joke_agent.py`. Replace the `__init__` method with this improved version -- we're keeping the same structure but enhancing the prompt sections and adding AI parameters:

Replace everything from `class WeatherJokeAgent` through the end of `__init__` (but keep the handler methods and DataMap registration the same):

`weather_joke_agent.py`

```python
#!/usr/bin/env python3
"""Polished agent with personality, hints, and tuned parameters."""

import json
import os
from datetime import datetime
import requests
from dotenv import load_dotenv
load_dotenv()

def check_ngrok():
    """Auto-detect ngrok tunnel and set SWML_PROXY_URL_BASE."""
    try:
        resp = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=1)
        tunnels = resp.json().get("tunnels", [])
        for t in tunnels:
            if t.get("proto") == "https":
                url = t["public_url"]
                os.environ["SWML_PROXY_URL_BASE"] = url
                print(f"ngrok detected: {url}")
                return url
    except Exception:
        pass
    current = os.getenv("SWML_PROXY_URL_BASE", "")
    if current:
        print(f"Using SWML_PROXY_URL_BASE from .env: {current}")
    else:
        print("No ngrok tunnel detected and SWML_PROXY_URL_BASE not set")
    return current

check_ngrok()

from signalwire_agents import AgentBase, SwaigFunctionResult
from signalwire_agents.core.data_map import DataMap

class WeatherJokeAgent(AgentBase):
    def __init__(self):
        super().__init__(name="weather-joke-agent")

        # Voice configuration with fillers for natural conversation
        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well", "So"],
            function_fillers=[
                "Let me check on that for you...",
                "One moment while I look that up...",
                "Hang on just a sec...",
            ]
        )

        # AI parameters for better conversation flow
        self.set_params({
            "end_of_speech_timeout": 600,    # Wait 600ms of silence before responding
            "attention_timeout": 15000,      # Prompt after 15s of silence
            "attention_timeout_prompt": "Are you still there? I can help with weather, jokes, or math!",
        })

        # Speech hints help the recognizer with tricky words
        self.add_hints(["Buddy", "weather", "joke", "temperature", "forecast"])

        # Structured prompt with personality
        self.prompt_add_section(
            "Personality",
            "You are Buddy, a cheerful and witty AI phone assistant. "
            "You have a warm, upbeat personality and you genuinely enjoy "
            "helping people. You're a bit of a dad joke enthusiast. "
            "Think of yourself as that friendly neighbor who always "
            "has a joke ready and knows what the weather is like."
        )

        self.prompt_add_section(
            "Voice Style",
            body="Since this is a phone conversation, follow these rules:",
            bullets=[
                "Keep responses to 1-2 sentences when possible",
                "Use conversational language, not formal or robotic",
                "React to what the caller says before jumping to information",
                "If they laugh at a joke, acknowledge it warmly",
                "Use natural transitions between topics",
            ]
        )

        self.prompt_add_section(
            "Capabilities",
            body="You can help with the following:",
            bullets=[
                "Weather: current conditions for any city worldwide",
                "Jokes: endless supply of dad jokes, always fresh",
                "General chat: friendly conversation on any topic",
            ]
        )

        self._register_joke_function()
        self._register_weather_datamap()

        # Post-prompt: summarize every call and save to calls/ folder
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Note what the caller asked about (weather, jokes, etc.) "
            "and how the interaction went."
        )

    def _register_joke_function(self):
        """Register the dad joke function (runs on our server)."""
        self.define_tool(
            name="tell_joke",
            description="Tell the caller a funny dad joke. Use this whenever someone asks for a joke or humor.",
            parameters={"type": "object", "properties": {}},
            handler=self.on_tell_joke,
            fillers={
                "en-US": [
                    "Let me think of a good one...",
                    "Oh, I've got one for you...",
                    "Here comes a good one...",
                ],
            },
        )

    def on_tell_joke(self, args, raw_data):
        api_key = os.getenv("API_NINJAS_KEY", "")
        if not api_key:
            return SwaigFunctionResult("Sorry, my joke book is unavailable right now.")

        try:
            resp = requests.get(
                "https://api.api-ninjas.com/v1/dadjokes",
                headers={"X-Api-Key": api_key},
                timeout=5,
            )
            resp.raise_for_status()
            jokes = resp.json()
            if jokes:
                return SwaigFunctionResult(f"Here's a dad joke: {jokes[0]['joke']}")
            return SwaigFunctionResult("I couldn't find a joke this time. Try again!")
        except requests.RequestException:
            return SwaigFunctionResult("My joke service is taking a break. Try again in a moment!")

    def _register_weather_datamap(self):
        """Register weather lookup via DataMap (runs on SignalWire's servers)."""
        api_key = os.getenv("WEATHER_API_KEY", "")

        weather_dm = (
            DataMap("get_weather")
            .description(
                "Get the current weather for a city. "
                "Use this when the caller asks about weather, temperature, or conditions."
            )
            .parameter("city", "string", "The city to get weather for", required=True)
            .webhook(
                "GET",
                f"https://api.weatherapi.com/v1/current.json?key={api_key}&q=${{enc:args.city}}"
            )
            .output(SwaigFunctionResult(
                "Weather in ${args.city}: ${response.current.condition.text}, "
                "${response.current.temp_f} degrees Fahrenheit, "
                "humidity ${response.current.humidity} percent. "
                "Feels like ${response.current.feelslike_f} degrees."
            ))
            .fallback_output(SwaigFunctionResult(
                "Sorry, I couldn't get the weather for ${args.city}. "
                "Please check the city name and try again."
            ))
        )

        self.register_swaig_function(weather_dm.to_swaig_function())

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging."""
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")

if __name__ == "__main__":
    agent = WeatherJokeAgent()
    agent.run()
```

What we improved:

- **`set_params()`** -- `end_of_speech_timeout` of 600ms means the agent waits a natural beat before responding (not jumping in too fast). `attention_timeout` of 15 seconds prompts the caller if they go quiet.
- **`add_hints()`** -- helps the speech recognizer with words it might mishear. "Buddy" could sound like "body" without a hint.
- **Richer prompts** -- the "Personality" section gives the AI a character to play. The "Voice Style" section has specific rules for phone conversation. The "Capabilities" section tells the AI what tools it has.
- **More fillers** -- multiple options per function so the agent doesn't say the same thing every time.

### Step 2: Test and Call

```bash
swaig-test weather_joke_agent.py --dump-swml
```

Look at the SWML -- you'll see the `hints` array, the `params` section with your timeouts, and the richer prompt. Restart and call:

```bash
python weather_joke_agent.py
```

The difference should be noticeable: the agent sounds more natural, has more personality, and handles pauses in conversation better.

> **Checkpoint:** Same capabilities (weather + jokes) but the conversation feels smoother and more natural. The agent has personality, uses varied filler phrases, and handles silence gracefully. Compare the experience to Section 8 -- it should be noticeably better.

---

## Section 10: Skills -- The Easy Way (10 min)

You've now built a custom function (jokes) and a DataMap function (weather). There's a third way to add capabilities: **skills**.

### What Are Skills?

Skills are pre-built capabilities that ship with the SDK. Adding one is a single line of code -- no handler to write, no API to call, no DataMap to configure. The SDK does everything.

### Step 1: Add DateTime and Math Skills

Edit `weather_joke_agent.py`. Add two lines inside `__init__`, after the `_register_weather_datamap()` call:

```python
        self._register_joke_function()
        self._register_weather_datamap()

        # Built-in skills -- one line each, zero configuration
        self.add_skill("datetime", {"default_timezone": "America/New_York"})
        self.add_skill("math")
```

Also update the "Capabilities" prompt section to mention the new abilities:

```python
        self.prompt_add_section(
            "Capabilities",
            body="You can help with the following:",
            bullets=[
                "Weather: current conditions for any city worldwide",
                "Jokes: endless supply of dad jokes, always fresh",
                "Date and time: current time in any timezone",
                "Math: calculations, percentages, conversions",
                "General chat: friendly conversation on any topic",
            ]
        )
```

That's it. Two lines of code just gave your agent the ability to tell time in any timezone and do math.

### Step 2: Compare the Approaches

Let's look at what it took to add each capability:

| Capability | Approach | Lines of Code | Your Server Handles It? |
|-----------|----------|---------------|------------------------|
| Dad Jokes | `define_tool` | ~30 lines | Yes |
| Weather | DataMap | ~15 lines | No (SignalWire) |
| DateTime | Skill | 1 line | No (built-in) |
| Math | Skill | 1 line | No (built-in) |

**When to use which:**

- **Skills** -- when one exists for what you need. Fastest path, zero maintenance
- **DataMap** -- when you need to call a REST API. No server code, SignalWire handles it
- **define_tool** -- when you need custom logic, database access, or complex processing

### Step 3: Test the New Skills

```bash
swaig-test weather_joke_agent.py --list-tools
```

You should see your original two functions plus the skill functions: `get_current_time`, `get_current_date`, and `calculate`.

```bash
swaig-test weather_joke_agent.py --exec get_current_time
swaig-test weather_joke_agent.py --exec calculate --expression "15/100 * 47.50"
```

### Step 4: Call and Test

Restart the agent and call:

```bash
python weather_joke_agent.py
```

Try asking:
- "What time is it?"
- "What time is it in Tokyo?"
- "What's 15% tip on a $47.50 bill?"
- "What's 144 divided by 12?"
- And of course: weather and jokes still work

> **Checkpoint:** Your agent now handles weather, jokes, time/date, and math. That's four capabilities, and two of them were a single line of code each. Verify all four work by calling and testing each one.

---

## Section 11: The Finished Agent (10 min)

Let's bring everything together into one clean, final version. This is the definitive `complete_agent.py` -- combining all four capabilities with polished prompts and tuned parameters.

### The Complete Agent

Create `complete_agent.py`:

`complete_agent.py`

```python
#!/usr/bin/env python3
"""
Complete Workshop Agent
-----------------------
A polished AI phone assistant with four capabilities:
  - Dad jokes via API Ninjas (custom define_tool)
  - Weather via WeatherAPI (serverless DataMap)
  - Date/time via built-in skill
  - Math via built-in skill

Run: python complete_agent.py
Test: swaig-test complete_agent.py --dump-swml
"""

import json
import os
from datetime import datetime
import requests
from dotenv import load_dotenv
load_dotenv()

def check_ngrok():
    """Auto-detect ngrok tunnel and set SWML_PROXY_URL_BASE."""
    try:
        resp = requests.get("http://127.0.0.1:4040/api/tunnels", timeout=1)
        tunnels = resp.json().get("tunnels", [])
        for t in tunnels:
            if t.get("proto") == "https":
                url = t["public_url"]
                os.environ["SWML_PROXY_URL_BASE"] = url
                print(f"ngrok detected: {url}")
                return url
    except Exception:
        pass
    current = os.getenv("SWML_PROXY_URL_BASE", "")
    if current:
        print(f"Using SWML_PROXY_URL_BASE from .env: {current}")
    else:
        print("No ngrok tunnel detected and SWML_PROXY_URL_BASE not set")
    return current

check_ngrok()

from signalwire_agents import AgentBase, SwaigFunctionResult
from signalwire_agents.core.data_map import DataMap


class CompleteAgent(AgentBase):
    def __init__(self):
        super().__init__(name="complete-agent")

        self._configure_voice()
        self._configure_params()
        self._configure_prompts()
        self._register_joke_function()
        self._register_weather_datamap()
        self._register_skills()
        self._configure_post_prompt()

    # ------------------------------------------------------------------
    # Voice and speech
    # ------------------------------------------------------------------

    def _configure_voice(self):
        self.add_language(
            "English", "en-US", "rime.spore",
            speech_fillers=["Um", "Well", "So"],
            function_fillers=[
                "Let me check on that for you...",
                "One moment while I look that up...",
                "Hang on just a sec...",
            ]
        )

        self.add_hints([
            "Buddy", "weather", "joke", "temperature",
            "forecast", "Fahrenheit", "Celsius",
        ])

    # ------------------------------------------------------------------
    # AI parameters
    # ------------------------------------------------------------------

    def _configure_params(self):
        self.set_params({
            "end_of_speech_timeout": 600,
            "attention_timeout": 15000,
            "attention_timeout_prompt":
                "Are you still there? I can help with weather, "
                "jokes, math, or just chat!",
        })

    # ------------------------------------------------------------------
    # Prompts
    # ------------------------------------------------------------------

    def _configure_prompts(self):
        self.prompt_add_section(
            "Personality",
            "You are Buddy, a cheerful and witty AI phone assistant. "
            "You have a warm, upbeat personality and you genuinely enjoy "
            "helping people. You're a bit of a dad joke enthusiast. "
            "Think of yourself as that friendly neighbor who always "
            "has a joke ready and knows what the weather is like."
        )

        self.prompt_add_section(
            "Voice Style",
            body="Since this is a phone conversation:",
            bullets=[
                "Keep responses to 1-2 sentences when possible",
                "Use conversational language, not formal or robotic",
                "React naturally to what the caller says",
                "Use smooth transitions between topics",
            ]
        )

        self.prompt_add_section(
            "Capabilities",
            body="You can help with:",
            bullets=[
                "Weather: current conditions for any city worldwide",
                "Jokes: endless supply of fresh dad jokes",
                "Date and time: current time in any timezone",
                "Math: calculations, percentages, unit conversions",
                "General chat: friendly conversation on any topic",
            ]
        )

        self.prompt_add_section(
            "Greeting",
            "When the call starts, introduce yourself as Buddy and "
            "briefly mention what you can help with. Keep the greeting "
            "to one or two sentences -- don't list every capability."
        )

    # ------------------------------------------------------------------
    # Dad jokes -- custom function calling API Ninjas
    # ------------------------------------------------------------------

    def _register_joke_function(self):
        self.define_tool(
            name="tell_joke",
            description=(
                "Tell the caller a funny dad joke. Use this whenever "
                "someone asks for a joke, humor, or to be entertained."
            ),
            parameters={"type": "object", "properties": {}},
            handler=self.on_tell_joke,
            fillers={
                "en-US": [
                    "Let me think of a good one...",
                    "Oh, I've got one for you...",
                    "Here comes a good one...",
                ],
            },
        )

    def on_tell_joke(self, args, raw_data):
        api_key = os.getenv("API_NINJAS_KEY", "")
        if not api_key:
            return SwaigFunctionResult(
                "Sorry, my joke book is unavailable right now."
            )

        try:
            resp = requests.get(
                "https://api.api-ninjas.com/v1/dadjokes",
                headers={"X-Api-Key": api_key},
                timeout=5,
            )
            resp.raise_for_status()
            jokes = resp.json()
            if jokes:
                return SwaigFunctionResult(
                    f"Here's a dad joke: {jokes[0]['joke']}"
                )
            return SwaigFunctionResult(
                "I couldn't find a joke this time. Try again!"
            )
        except requests.RequestException:
            return SwaigFunctionResult(
                "My joke service is taking a break. Try again in a moment!"
            )

    # ------------------------------------------------------------------
    # Weather -- DataMap (runs on SignalWire, not our server)
    # ------------------------------------------------------------------

    def _register_weather_datamap(self):
        api_key = os.getenv("WEATHER_API_KEY", "")

        weather_dm = (
            DataMap("get_weather")
            .description(
                "Get the current weather for a city. Use this when "
                "the caller asks about weather, temperature, or conditions."
            )
            .parameter(
                "city", "string",
                "The city to get weather for",
                required=True,
            )
            .webhook(
                "GET",
                "https://api.weatherapi.com/v1/current.json"
                f"?key={api_key}&q=${{enc:args.city}}"
            )
            .output(SwaigFunctionResult(
                "Weather in ${args.city}: "
                "${response.current.condition.text}, "
                "${response.current.temp_f} degrees Fahrenheit, "
                "humidity ${response.current.humidity} percent. "
                "Feels like ${response.current.feelslike_f} degrees."
            ))
            .fallback_output(SwaigFunctionResult(
                "Sorry, I couldn't get the weather for ${args.city}. "
                "Please check the city name and try again."
            ))
        )

        self.register_swaig_function(weather_dm.to_swaig_function())

    # ------------------------------------------------------------------
    # Skills -- built-in, zero-code capabilities
    # ------------------------------------------------------------------

    def _register_skills(self):
        self.add_skill("datetime", {"default_timezone": "America/New_York"})
        self.add_skill("math")

    # ------------------------------------------------------------------
    # Post-prompt -- save call summaries for debugging
    # ------------------------------------------------------------------

    def _configure_post_prompt(self):
        self.set_post_prompt(
            "Summarize this conversation in 2-3 sentences. "
            "Note what the caller asked about (weather, jokes, time, math, etc.) "
            "and how the interaction went."
        )

    def on_summary(self, summary, raw_data):
        """Save post-prompt data to calls/ folder for debugging.

        View saved files at: https://postpromptviewer.signalwire.io/
        """
        os.makedirs("calls", exist_ok=True)
        call_id = (raw_data or {}).get("call_id", datetime.now().strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join("calls", f"{call_id}.json")
        with open(filepath, "w") as f:
            json.dump(raw_data, f, indent=2, default=str)
        print(f"Call summary saved: {filepath}")


if __name__ == "__main__":
    agent = CompleteAgent()
    agent.run()
```

### What's Different From the Iterative Version?

Structurally, very little. This is the same agent you've been building, just organized into clean private methods:

- `_configure_voice()` -- voice, fillers, hints
- `_configure_params()` -- AI behavior tuning
- `_configure_prompts()` -- personality and instructions
- `_register_joke_function()` -- custom SWAIG function
- `_register_weather_datamap()` -- serverless DataMap
- `_register_skills()` -- built-in skills
- `_configure_post_prompt()` -- call summaries saved to `calls/`

This pattern (`_configure_*` and `_register_*` methods) is the standard way to organize larger agents in the SDK.

> **Debugging with Post-Prompt Viewer:** After each call, check your `calls/` folder -- you'll find a JSON file for every conversation. Upload these files to [postpromptviewer.signalwire.io](https://postpromptviewer.signalwire.io/) to visualize the full conversation flow, see what functions were called, and read the AI-generated summary. It's the fastest way to debug and improve your agent.

### Test Everything

```bash
# Verify configuration
swaig-test complete_agent.py --dump-swml

# List all tools
swaig-test complete_agent.py --list-tools

# Test individual functions
swaig-test complete_agent.py --exec tell_joke
swaig-test complete_agent.py --exec get_current_time
swaig-test complete_agent.py --exec calculate --expression "20 * 1.15"
```

### Go Live

```bash
python complete_agent.py
```

Call your number and run through all the capabilities:

1. "Hey, what time is it?" -- datetime skill
2. "What's the weather in Paris?" -- DataMap weather
3. "Tell me a joke!" -- API Ninjas dad jokes
4. "What's 18% tip on $86?" -- math skill
5. "Thanks Buddy, you're great!" -- personality shines

> **Checkpoint:** All four capabilities work end-to-end through a phone call. Your agent has personality, handles pauses naturally, and uses filler phrases while thinking. This is your complete, polished AI phone assistant. Congratulations -- you built this!

---

## Section 12: Where to Go From Here (5 min)

You've built a working AI phone agent in about two hours. Let's look at what's possible next.

### What You've Learned

- **AgentBase** -- the foundation for every agent
- **Prompts** -- structured personality and instructions using `prompt_add_section()`
- **define_tool** -- custom Python functions the AI can call
- **DataMap** -- serverless API calls that run on SignalWire's infrastructure
- **Skills** -- pre-built capabilities, one line each
- **AI parameters** -- tuning conversation flow and behavior
- **Speech hints and fillers** -- making conversations sound natural
- **ngrok auto-detection** -- querying the local ngrok API to streamline development
- **Post-prompt and on_summary** -- saving call data for debugging with the Post-Prompt Viewer

### What's Possible Next

The agent you built today is a starting point. Here's a taste of what the SDK can do:

**Contexts and Workflows** -- guide conversations through structured steps. Imagine an appointment scheduler that walks through date, time, service type, and confirmation -- each step with its own prompt and available functions.

**State Management** -- track information across the call with global data. Remember the caller's name, build up an order, track verification status.

**Prefab Agents** -- `InfoGathererAgent` is a pre-built agent designed to collect structured data from callers (name, email, phone, custom fields) with built-in validation and retry logic.

**Multi-Agent Servers** -- run multiple agents on different routes from one server. A sales agent on `/sales`, support on `/support`, with SIP routing to direct calls.

**DataSphere and Vector Search** -- connect your agent to knowledge bases. Upload documents and your agent can search them to answer questions.

**Call Recording and Post-Call Processing** -- record calls, generate summaries, extract structured data after each call.

**Transfer and Conference** -- transfer callers to humans, join conference rooms, or hand off between AI agents.

### Resources

- **SDK Repository:** [github.com/signalwire/signalwire-agents](https://github.com/signalwire/signalwire-agents) -- source code, examples, and issues
- **SignalWire Documentation:** [developer.signalwire.com](https://developer.signalwire.com) -- platform docs, SWML reference, REST APIs
- **SignalWire Community:** [signalwire.community](https://signalwire.community) -- forums, Q&A, and community projects

### Your Files

Here's what you created today:

```
workshop-agent/
├── .env                      # Your API keys and configuration
├── requirements.txt          # Python dependencies
├── hello_agent.py            # Section 4 -- minimal agent
├── joke_agent.py             # Sections 6-7 -- jokes (hardcoded, then API)
├── weather_joke_agent.py     # Sections 8-10 -- weather + jokes + skills
├── complete_agent.py         # Section 11 -- the final polished version
└── calls/                    # Post-prompt data saved after each call
    ├── abc123-def456.json    # One JSON file per call
    └── ...
```

Upload files from `calls/` to [postpromptviewer.signalwire.io](https://postpromptviewer.signalwire.io/) to visualize your conversations.

### Congratulations

You went from zero to a phone-callable AI assistant with four capabilities, built three different ways. You understand the core concepts of the SignalWire AI Agents SDK, and you have a working codebase to experiment with.

The agent running on your laptop right now is the same technology powering production voice AI systems. The patterns you learned today -- custom functions, DataMap, skills, structured prompts -- scale from this workshop project to enterprise deployments.

Go build something great.

---

## Quick Reference

### Common swaig-test Commands

```bash
swaig-test your_agent.py --dump-swml          # View full SWML configuration
swaig-test your_agent.py --list-tools         # List registered functions
swaig-test your_agent.py --exec func_name     # Execute a function
swaig-test your_agent.py --exec calc --expression "2+2"  # With arguments
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `SWML_BASIC_AUTH_USER` | Username for agent authentication |
| `SWML_BASIC_AUTH_PASSWORD` | Password for agent authentication |
| `SWML_PROXY_URL_BASE` | Auto-detected from ngrok; set manually only if not using ngrok |
| `WEATHER_API_KEY` | WeatherAPI.com API key |
| `API_NINJAS_KEY` | API Ninjas API key |

### Three Ways to Add Capabilities

```python
# 1. Custom function (full control, runs on your server)
self.define_tool(name="...", description="...", parameters={...}, handler=self.my_handler)

# 2. DataMap (serverless, runs on SignalWire)
dm = DataMap("name").description("...").parameter(...).webhook(...).output(...)
self.register_swaig_function(dm.to_swaig_function())

# 3. Skill (pre-built, one line)
self.add_skill("skill_name", {config})
```

### Troubleshooting

| Problem | Solution |
|---------|----------|
| Agent won't start | Check venv is activated and dependencies installed |
| Can't reach agent from internet | Is ngrok running? Check `http://127.0.0.1:4040` |
| SignalWire can't reach agent | Verify SWML URL has trailing slash, auth matches |
| Weather returns errors | Check `WEATHER_API_KEY` in `.env` |
| Jokes return errors | Check `API_NINJAS_KEY` in `.env` |
| Agent doesn't call functions | Check function `description` -- AI needs clear guidance |
| Speech recognition is wrong | Add `add_hints()` for commonly misheard words |
| Agent responds too fast | Increase `end_of_speech_timeout` in `set_params()` |
| Agent goes silent | Decrease `attention_timeout` in `set_params()` |
