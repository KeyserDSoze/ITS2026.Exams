const list = document.querySelector('#books');
const form = document.querySelector('#book-form');
const input = document.querySelector('#title');
const message = document.querySelector('#message');

async function loadBooks() {
  const response = await fetch('/api/books');
  if (!response.ok) throw new Error('Errore caricamento libri.');
  const books = await response.json();
  list.replaceChildren();
  for (const book of books) {
    const li = document.createElement('li');
    li.textContent = book.title;
    list.appendChild(li);
  }
}
form.addEventListener('submit', async (event) => {
  event.preventDefault();
  message.textContent = '';
  try {
    const response = await fetch('/api/books', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: input.value })
    });
    if (!response.ok) {
      const problem = await response.json().catch(() => ({}));
      throw new Error(problem.error || 'Errore inserimento.');
    }
    input.value = '';
    message.textContent = 'Libro aggiunto.';
    await loadBooks();
  } catch (error) {
    message.textContent = error.message;
  }
});
loadBooks().catch(error => { message.textContent = error.message; });
