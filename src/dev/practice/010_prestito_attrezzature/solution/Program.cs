var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Equipment> { new(1, "Proiettore", false) };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/equipment", () => Results.Ok(entries));

app.MapPost("/api/equipment", (CreateEquipment request) =>
{
    var name = request.Name?.Trim();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Name obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Equipment(nextId, name, false);
    entries.Add(item);
    return Results.Created($"/api/equipment/{item.Id}", item);
});

// PATCH: aggiorna solamente lo stato booleano.
app.MapPatch("/api/equipment/{id:int}", (int id, UpdateState request) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    var updated = entries[index] with { Reserved = request.State };
    entries[index] = updated;
    return Results.Ok(updated);
});

app.MapDelete("/api/equipment/{id:int}", (int id) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    entries.RemoveAt(index);
    return Results.NoContent();
});

app.Run();

record Equipment(int Id, string Name, bool Reserved);
record CreateEquipment(string? Name);
record UpdateState(bool State);
