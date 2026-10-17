var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Ticket> { new(1, "Stampante offline") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/tickets", () => Results.Ok(entries));

app.MapPost("/api/tickets", (CreateTicket request) =>
{
    var description = request.Description?.Trim();
    if (string.IsNullOrWhiteSpace(description))
        return Results.BadRequest(new { error = "Description obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Ticket(nextId, description);
    entries.Add(item);
    return Results.Created($"/api/tickets/{item.Id}", item);
});

app.Run();

record Ticket(int Id, string Description);
record CreateTicket(string? Description);
