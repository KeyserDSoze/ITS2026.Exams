var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Booking> { new(1, "Aula 1", "Lezione mattutina") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/bookings", () => Results.Ok(entries));

app.MapPost("/api/bookings", (CreateBooking request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Name e Note.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Booking(int Id, string Name, string Note);
record CreateBooking(string? Name, string? Note);
