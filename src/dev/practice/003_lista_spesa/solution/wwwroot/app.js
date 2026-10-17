const list = document.querySelector('#entries');
const form = document.querySelector('#entry-form');
const input = document.querySelector('#name');
const message = document.querySelector('#message');

async function loadEntries() {
  const response = await fetch('/api/shopping-items');
  if (!response.ok) throw new Error('Errore nel caricamento.');
  const entries = await response.json();
  list.replaceChildren();
  for (const entry of entries) {
    const li = document.createElement('li');
    li.className = 'entry-card';
    const content = document.createElement('span');
    content.textContent = entry.name;
    li.appendChild(content);
    list.appendChild(li);
  }
}


form.addEventListener('submit', async (event) => {
  event.preventDefault();
  message.textContent = '';
  try {
    const response = await fetch('/api/shopping-items', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: input.value })
    });
    if (!response.ok) {
      const problem = await response.json().catch(() => ({}));
      throw new Error(problem.error || 'Inserimento non riuscito.');
    }
    input.value = '';
    message.textContent = 'Elemento aggiunto.';
    await loadEntries();
  } catch (error) {
    message.textContent = error.message;
  }
});

loadEntries().catch(error => { message.textContent = error.message; });
