var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Ticket> { new(1, "Stampante offline") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/tickets", () => Results.Ok(entries));

app.MapPost("/api/tickets", (CreateTicket request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Description.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Ticket(int Id, string Description);
record CreateTicket(string? Description);
