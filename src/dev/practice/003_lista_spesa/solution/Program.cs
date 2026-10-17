var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<ShoppingItem> { new(1, "Pane") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/shopping-items", () => Results.Ok(entries));

app.MapPost("/api/shopping-items", (CreateShoppingItem request) =>
{
    var name = request.Name?.Trim();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Name obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new ShoppingItem(nextId, name);
    entries.Add(item);
    return Results.Created($"/api/shopping-items/{item.Id}", item);
});

app.Run();

record ShoppingItem(int Id, string Name);
record CreateShoppingItem(string? Name);
