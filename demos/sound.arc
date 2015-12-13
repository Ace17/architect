
root()
{
  sound(20);
  melody();
//  square(4220);
  amplify(0.1);
  delay();
}

melody()
{
  let A3 = 220;
  let A4 = 440;
  let C5 = 523.25;
  let E5 = 659.25;
  let A5 = 880;

  note(A4, 0);
  note(C5, 2);
  note(E5, 4);
}

note(freq, when)
{
  sine(freq, when, 1);
  envelope(when, 1);
}
