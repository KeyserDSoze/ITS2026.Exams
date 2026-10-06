const list = document.querySelector('#items');
const form = document.querySelector('#item-form');
const input = document.querySelector('#name');
const message = document.querySelector('#message');

async function loadItems() {
  // TODO: chiamare GET /api/items e renderizzare gli elementi dentro #items.
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  // TODO: inviare POST /api/items con JSON { name: input.value }.
  // TODO: mostrare un messaggio di conferma/errore e ricaricare la lista.
});

loadItems();
