var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<ShoppingItem> { new(1, "Pane") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/shopping-items", () => Results.Ok(entries));

app.MapPost("/api/shopping-items", (CreateShoppingItem request) =>
{
    // TODO 1: con Trim e IsNullOrWhiteSpace validare Name.
    // TODO 2: input non valido -> Results.BadRequest(new { error = "..." }).
    // TODO 3: generare ID progressivo e aggiungere il record a entries.
    // TODO 4: tornare Results.Created(...) con il nuovo oggetto.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record ShoppingItem(int Id, string Name);
record CreateShoppingItem(string? Name);
