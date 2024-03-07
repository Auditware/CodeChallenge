# "Let's Play the Lottery" - Audit Wizard Find the Bug Challenge #2

Audit Wizard's find-the-bug challenges test your knowledge of smart contract security and solidity. Unlike simple code snippet challenges, Audit Wizard challenges present you with a fully functional contract with a security vulnerability. You must figure out where the bug is and submit your answer using the "Submit Answer" button.

Correctly finding the bug will unlock a commemorative badge in Audit Wizard. The badge will be added to your auditor profile. This is just the start—participate in each challenge to build your collection!

---

**Out-of-scope issues**

- Issues related to randomness are out of scope. Assume all randomness is secure.
- Issues related to large loops leading to out of gas issues, assume all loops will stay within gas boundaries.

---

This challenge by [JohnnyTime](https://twitter.com/RealJohnnyTime) includes a community-managed lottery system. Each lottery contest is open for a minimum of 1 day, and participants can purchase as many lottery tickets as they want. Each ticket has an equal chance of being selected as a winner. After 1 day, any community member (or lottery admin) may call the function to resolve the previous lottery, process rewards, and open a new lottery contest for submissions.

It's been rumored that a malicious spellcaster can find a way to drain this lottery contract. Locate the vulnerability that allows the contract to be drained before bad actors can get to it.

Happy hunting!

![img](https://i.ibb.co/bBzMmNt/21239f45d36c1497ac703c2a1e27da37.png)
