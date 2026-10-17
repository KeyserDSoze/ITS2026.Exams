var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseDefaultFiles();
app.UseStaticFiles();

var entries = new List<Course> { new(1, "Fondamenti di C#") };

// GET iniziale gia completo: osserva la risposta JSON nel browser.
app.MapGet("/api/courses", () => Results.Ok(entries));

app.MapPost("/api/courses", (CreateCourse request) =>
{
    var title = request.Title?.Trim();
    if (string.IsNullOrWhiteSpace(title))
        return Results.BadRequest(new { error = "Title obbligatorio." });

    var nextId = entries.Count == 0 ? 1 : entries.Max(e => e.Id) + 1;
    var item = new Course(nextId, title);
    entries.Add(item);
    return Results.Created($"/api/courses/{item.Id}", item);
});

// PUT: sostituisce il titolo del corso identificato dall'id.
app.MapPut("/api/courses/{id:int}", (int id, CreateCourse request) =>
{
    var title = request.Title?.Trim();
    if (string.IsNullOrWhiteSpace(title))
        return Results.BadRequest(new { error = "Title obbligatorio." });
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    var updated = entries[index] with { Title = title };
    entries[index] = updated;
    return Results.Ok(updated);
});

app.MapDelete("/api/courses/{id:int}", (int id) =>
{
    var index = entries.FindIndex(e => e.Id == id);
    if (index < 0) return Results.NotFound();
    entries.RemoveAt(index);
    return Results.NoContent();
});

app.Run();

record Course(int Id, string Title);
record CreateCourse(string? Title);
