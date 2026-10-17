var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Movie> { new(1, "Interstellar") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/movies", () => Results.Ok(entries));

app.MapPost("/api/movies", (CreateMovie request) =>
{
    var title = request.Title?.Trim();
    if (string.IsNullOrWhiteSpace(title))
        return Results.BadRequest(new { error = "Title obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Movie(nextId, title);
    entries.Add(item);
    return Results.Created($"/api/movies/{item.Id}", item);
});

app.MapDelete("/api/movies/{id:int}", (int id) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    entries.RemoveAt(index);
    return Results.NoContent();
});

app.Run();

record Movie(int Id, string Title);
record CreateMovie(string? Title);
