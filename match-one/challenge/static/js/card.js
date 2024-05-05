// Based on tutorial - https://github.com/code-sketch/memory-game
const cards = document.querySelectorAll('.memory-card');

let hasFlippedCard = false;
let lockBoard = false;
let firstCard, secondCard;

function flipCard() {
  if (lockBoard) return;
  if (this === firstCard) return;

  this.classList.add('flip');

  if (!hasFlippedCard) {
    hasFlippedCard = true;
    firstCard = this;

    return;
  }

  secondCard = this;
  checkForMatch();
}

function checkForMatch() {
  let isMatch = firstCard.dataset.value === secondCard.dataset.value;
    $.get(`/match?first_val=${encodeURIComponent(firstCard.dataset.value)}&first_pos=${encodeURIComponent(firstCard.dataset.id)}&second_val=${encodeURIComponent(secondCard.dataset.value)}&second_pos=${encodeURIComponent(secondCard.dataset.id)}`, function(data, textStatus, jqXHR) {
    console.log("Data:", data);
    console.log("Status:", textStatus);
    // Use the data returned from the server
    }, "json"); // Specify data type as JSON
  isMatch ? disableCards() : unflipCards();
}

function disableCards() {
  firstCard.removeEventListener('click', flipCard);
  secondCard.removeEventListener('click', flipCard);
  resetBoard();
}

function unflipCards() {
  lockBoard = true;
  setTimeout(() => {
    firstCard.classList.remove('flip');
    secondCard.classList.remove('flip');
    resetBoard();
  }, 1500);
}

function resetBoard() {
  [hasFlippedCard, lockBoard] = [false, false];
  [firstCard, secondCard] = [null, null];
}

cards.forEach(card => card.addEventListener('click', flipCard));