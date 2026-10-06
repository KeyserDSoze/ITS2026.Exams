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
    var name = request.Name?.Trim();
    if (string.IsNullOrWhiteSpace(name))
        return Results.BadRequest(new { error = "Il nome è obbligatorio." });

    var nextId = items.Count == 0 ? 1 : items.Max(x => x.Id) + 1;
    var item = new Item(nextId, name);
    items.Add(item);
    return Results.Created($"/api/items/{item.Id}", item);
});

app.Run();

record Item(int Id, string Name);
record CreateItem(string? Name);
