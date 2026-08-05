# Sample lab (local Docker)

A tiny sample task that demonstrates the local (Docker) lab target end to end.

You are given SSH access to a Linux container (credentials are shown in the lab's
**Credentials** panel — host, user, password). Connect to it and complete the task below.

## Task

1. Connect to the lab over SSH as the `learner` user.
2. Write the word `done` into `answer.txt` in your home directory:

   ```shell
   echo done > ~/answer.txt
   ```

The grader connects over SSH and checks that you can log in and that
`~/answer.txt` contains `done`.

![Sample Image](./assets/sample-photo.jpeg)
