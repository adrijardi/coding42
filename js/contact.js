function sendToAPI(e) {
  e.preventDefault();

  const name = document.getElementById("name-input").value;
  const email = document.getElementById("email-input").value;
  const message = document.getElementById("message-input").value;

  const nameRegex = /[A-Za-z]{1}[A-Za-z]/;
  if (!nameRegex.test(name)) {
    alert ("Name can not less than 2 char");
    return;
  }

  if (email === "") {
    alert ("Please enter your email address");
    return;
  }
  const emailRegex = /^([\w-\.]+@([\w-]+\.)+[\w-]{2,6})?$/;
  if (!emailRegex.test(email)) {
    alert ("Please enter valid email address");
    return;
  }

  if (message === "") {
    alert ("Please enter a message");
    return;
  }

  const data = {
    name : name,
    email : email,
    message : message
  };

  fetch('https://uvgh6tpjf6.execute-api.eu-west-1.amazonaws.com/dev/contact', {
    json: true,
    method: 'POST',
    body: JSON.stringify(data),
  }).then(function(data) {
    console.log(data);
  });

}
