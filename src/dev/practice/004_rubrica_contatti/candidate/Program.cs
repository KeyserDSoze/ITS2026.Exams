var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Contact> { new(1, "Ada Lovelace", "ada@example.test") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/contacts", () => Results.Ok(entries));

app.MapPost("/api/contacts", (CreateContact request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Name e Email.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Contact(int Id, string Name, string Email);
record CreateContact(string? Name, string? Email);
