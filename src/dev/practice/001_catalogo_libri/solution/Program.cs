var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Book> { new(1, "Il nome della rosa") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/books", () => Results.Ok(entries));

app.MapPost("/api/books", (CreateBook request) =>
{
    var title = request.Title?.Trim();
    if (string.IsNullOrWhiteSpace(title))
        return Results.BadRequest(new { error = "Title obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Book(nextId, title);
    entries.Add(item);
    return Results.Created($"/api/books/{item.Id}", item);
});

app.Run();

record Book(int Id, string Title);
record CreateBook(string? Title);
