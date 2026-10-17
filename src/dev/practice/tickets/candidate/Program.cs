var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.UseDefaultFiles();
app.UseStaticFiles();
var tickets = new List<Ticket> { new(1, "Stampante non disponibile") };

app.MapGet("/api/tickets", () => Results.Ok(tickets));
app.MapPost("/api/tickets", (CreateTicket request) =>
{
    // TODO: validare request.Description, escludendo valori null/vuoti/spazi.
    // TODO: creare il ticket con ID progressivo, inserirlo in memoria.
    // TODO: restituire HTTP 201 e l'oggetto appena creato.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});
app.Run();
record Ticket(int Id, string Description);
record CreateTicket(string? Description);
