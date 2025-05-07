import { Elm } from "./Main.elm";
import { Amplify } from "aws-amplify";
import { generateClient } from "aws-amplify/data";
import type { Schema } from "../amplify/data/resource";
import outputs from "../amplify_outputs.json";
import "./style.css";

// 1) Configure Amplify & generate the typed client
Amplify.configure(outputs);
const client = generateClient<Schema>();

// 2) Mount Elm
const app = Elm.Main.init({
  node: document.getElementById("elm-node"),
});

// 3) When Elm asks for the full list:
if (app.ports.getTodos) {
  app.ports.getTodos.subscribe(async () => {
    const result = await client.models.Todo.list();
    const todos = result.data.map((t) => ({
      id: t.id,
      content: t.content ?? "",
    }));
    app.ports.receiveTodos.send(todos);
  });
}

// 4) When Elm asks to create a new item:
if (app.ports.createTodo) {
  app.ports.createTodo.subscribe(async (content: string) => {
    const result = await client.models.Todo.create({ content });
    if (result.data) {
      // push just the new item back into Elm:
      app.ports.newTodoCreated.send(result.data.content!);
    }
  });
}
if (app.ports.removeTodo) {
  app.ports.removeTodo.subscribe(async (id: string) => {
    const result = await client.models.Todo.delete({ id });
    if (result.data && app.ports.todoDeleted) {
      app.ports.todoDeleted.send(id);
    }
  });
}
