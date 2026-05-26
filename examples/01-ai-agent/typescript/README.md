# Pillar 1 — AI Agent (TypeScript)

Closing-demo language. Same UI, same behavior, same SDK surface as the Python reference.

## Run

```bash
npm install
npm start
# Open http://localhost:8000
```

Same UI flow as Python: paste creds → pick a number → call it.

## How the agent looks in TypeScript

```ts
import { AgentBase, DataMap, FunctionResult } from "@signalwire/sdk";

class WorkshopAgent extends AgentBase {
  constructor() {
    super({ name: "workshop-agent", route: "/agent" });
    void this.addSkillByName("datetime");
    void this.addSkillByName("math");
    this.defineTool({
      name: "tell_joke",
      description: "Tell a fresh dad joke.",
      parameters: { type: "object", properties: {}, required: [] },
      handler: async () => new FunctionResult("..."),
    });
  }
}
```

Same shape as Python: `add_skill` → `addSkillByName`, `define_tool` → `defineTool`, `register_swaig_function` → `registerSwaigFunction`. Each port uses idiomatic naming.
