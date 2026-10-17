var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.UseDefaultFiles();
app.UseStaticFiles();
var books = new List<Book> { new(1, "Il nome della rosa") };

app.MapGet("/api/books", () => Results.Ok(books));
app.MapPost("/api/books", (CreateBook request) =>
{
    var title = request.Title?.Trim();
    if (string.IsNullOrWhiteSpace(title))
        return Results.BadRequest(new { error = "Titolo obbligatorio." });
    var nextId = books.Count == 0 ? 1 : books.Max(b => b.Id) + 1;
    var book = new Book(nextId, title);
    books.Add(book);
    return Results.Created($"/api/books/{book.Id}", book);
});
app.Run();
record Book(int Id, string Title);
record CreateBook(string? Title);
