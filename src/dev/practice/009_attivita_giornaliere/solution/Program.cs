var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<TaskItem> { new(1, "Preparare report", false) };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/tasks", () => Results.Ok(entries));

app.MapPost("/api/tasks", (CreateTaskItem request) =>
{
    var name = request.Name?.Trim();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Name obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new TaskItem(nextId, name, false);
    entries.Add(item);
    return Results.Created($"/api/tasks/{item.Id}", item);
});

// PATCH: aggiorna solamente lo stato booleano.
app.MapPatch("/api/tasks/{id:int}", (int id, UpdateState request) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    var updated = entries[index] with { Done = request.State };
    entries[index] = updated;
    return Results.Ok(updated);
});

app.Run();

record TaskItem(int Id, string Name, bool Done);
record CreateTaskItem(string? Name);
record UpdateState(bool State);
