var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Expense> { new(1, "Treno", "Viaggio di lavoro") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/expenses", () => Results.Ok(entries));

app.MapPost("/api/expenses", (CreateExpense request) =>
{
    var name = request.Name?.Trim();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Name obbligatorio." });
    var note = request.Note?.Trim();
    if (string.IsNullOrWhiteSpace(note))
        return Results.BadRequest(new { error = "Note obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Expense(nextId, name, note);
    entries.Add(item);
    return Results.Created($"/api/expenses/{item.Id}", item);
});

app.MapDelete("/api/expenses/{id:int}", (int id) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    entries.RemoveAt(index);
    return Results.NoContent();
});

app.Run();

record Expense(int Id, string Name, string Note);
record CreateExpense(string? Name, string? Note);
