var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Booking> { new(1, "Aula 1", "Lezione mattutina") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/bookings", () => Results.Ok(entries));

app.MapPost("/api/bookings", (CreateBooking request) =>
{
    var name = request.Name?.Trim();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Name obbligatorio." });
    var note = request.Note?.Trim();
    if (string.IsNullOrWhiteSpace(note))
        return Results.BadRequest(new { error = "Note obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Booking(nextId, name, note);
    entries.Add(item);
    return Results.Created($"/api/bookings/{item.Id}", item);
});

app.Run();

record Booking(int Id, string Name, string Note);
record CreateBooking(string? Name, string? Note);
