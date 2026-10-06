const list = document.querySelector('#items');
const form = document.querySelector('#item-form');
const input = document.querySelector('#name');
const message = document.querySelector('#message');

async function loadItems() {
  const response = await fetch('/api/items');
  const items = await response.json();
  list.innerHTML = '';
  for (const item of items) {
    const li = document.createElement('li');
    li.textContent = item.name;
    list.appendChild(li);
  }
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  const response = await fetch('/api/items', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: input.value })
  });
  message.textContent = response.ok ? 'Elemento aggiunto.' : 'Errore.';
  if (response.ok) {
    input.value = '';
    await loadItems();
  }
});

loadItems();
