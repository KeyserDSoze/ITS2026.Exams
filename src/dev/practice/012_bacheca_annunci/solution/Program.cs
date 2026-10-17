var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Announcement> { new(1, "Riunione di classe", false) };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/announcements", () => Results.Ok(entries));

app.MapPost("/api/announcements", (CreateAnnouncement request) =>
{
    var title = request.Title?.Trim();
    if (string.IsNullOrWhiteSpace(title))
        return Results.BadRequest(new { error = "Title obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Announcement(nextId, title, false);
    entries.Add(item);
    return Results.Created($"/api/announcements/{item.Id}", item);
});

// PATCH: aggiorna solamente lo stato booleano.
app.MapPatch("/api/announcements/{id:int}", (int id, UpdateState request) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    var updated = entries[index] with { Published = request.State };
    entries[index] = updated;
    return Results.Ok(updated);
});

app.MapDelete("/api/announcements/{id:int}", (int id) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    entries.RemoveAt(index);
    return Results.NoContent();
});

app.Run();

record Announcement(int Id, string Title, bool Published);
record CreateAnnouncement(string? Title);
record UpdateState(bool State);
