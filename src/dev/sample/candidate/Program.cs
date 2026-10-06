var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var items = new List<Item>
{
    new(1, "Elemento di esempio")
};

app.MapGet("/api/items", () => Results.Ok(items));

app.MapPost("/api/items", (CreateItem request) =>
{
    // TODO: validare request.Name. Se vuoto, restituire HTTP 400.
    // TODO: creare un nuovo Item con id progressivo, aggiungerlo alla lista
    //       e restituire HTTP 201 con l'oggetto creato.
    return Results.StatusCode(StatusCodes.Status501NotImplemented);
});

app.Run();

record Item(int Id, string Name);
record CreateItem(string? Name);
