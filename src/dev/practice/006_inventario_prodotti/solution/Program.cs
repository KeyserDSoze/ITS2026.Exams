var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Product> { new(1, "Tastiera") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/products", () => Results.Ok(entries));

app.MapPost("/api/products", (CreateProduct request) =>
{
    var name = request.Name?.Trim();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Name obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Product(nextId, name);
    entries.Add(item);
    return Results.Created($"/api/products/{item.Id}", item);
});

app.MapDelete("/api/products/{id:int}", (int id) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    entries.RemoveAt(index);
    return Results.NoContent();
});

app.Run();

record Product(int Id, string Name);
record CreateProduct(string? Name);
