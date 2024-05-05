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
  let isMatch = false;
    $.get(`/match?first_pos=${encodeURIComponent(firstCard.dataset.id)}&second_pos=${encodeURIComponent(secondCard.dataset.id)}`, function(data, textStatus, jqXHR) {
    try {
    // const jsonData = JSON.parse(data);
    const jsonData = data;

    const first_outer_element = document.querySelector(`div[data-id="${firstCard.dataset.id}"]`);
    first_outer_element.querySelector('img[class="front-face"]').src = `data:image/svg+xml;base64,${jsonData.first_svgdata}`;
    const second_outer_element = document.querySelector(`div[data-id="${secondCard.dataset.id}"]`);
    second_outer_element.querySelector('img[class="front-face"]').src = `data:image/svg+xml;base64,${jsonData.second_svgdata}`;

    if (jsonData.hasOwnProperty('state') && jsonData.state === 1) {
      isMatch = true;
    } else {
      // Handle other responses (optional)
    }
  } catch (error) {
    console.error("Error parsing JSON response:", error);
  }
    isMatch ? disableCards() : unflipCards();
    }, "json"); // Specify data type as JSON
  
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