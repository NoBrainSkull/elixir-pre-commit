defmodule PreCommit do
  @moduledoc """
  This is a module for setting up pre-commit hooks on elixir projects. It's
  inspired by [pre-commit](https://www.npmjs.com/package/pre-commit) on npm
  and [pre_commit_hook](https://hex.pm/packages/pre_commit_hook) for Elixir

  We wanted something which was configurable with your own mix commands and
  just in elixir, so we created our own module. This module will only work
  with git versions 2.13 and above  The first step will be to add this module to your mix.exs.
  ```elixir
  def deps do
    [{:pre_commit, "~> 0.3.4", only: :dev}]
  end
  ```
  Then run mix deps.get. When the module is installed it will either create or overwrite your current `pre-commit` file in your `.git/hooks` directory  In your config file you will have to add in this line:
  ```elixir
    config :pre_commit, commands: ["test"]
  ```
  You can add any mix commands to the list, and these will run on commit,
  stopping the commit if they fail, or allowing the commit if they all pass  You can also have pre-commit display the output of the commands you run by
  setting the :verbose option.
  ```
  config :pre_commit,
  commands: ["test"],
  verbose: true
  ```

  You will have to compile your app before committing in order for the pre-commit to work  As a note, this module will only work with scripts which exit with a code of
  `1` on error, and a code of `0` on success. Some commands always exit with a
  `0` (success), so just make sure the command uses the right format before
  putting it in your pre-commit  We like adding [credo](https://github.com/rrrene/credo) and
  [coveralls](https://github.com/parroty/excoveralls) as well as `test`, to
  keep our code consistent and well covered!

  There is a [known issue](https://github.com/dwyl/elixir-pre-commit/issues/32)
  with the fact that running the pre-commit will restore deleted files to the working
  tree.
  """
  @git_folder_name Application.get_env(:pre_commit, :git_folder_name) || ".git"
  @root Application.get_env(:pre_commit, :root) || Path.join(Mix.Project.deps_path(), "..")
  @content Path.join(@root, "priv/pre-commit")
  @target Path.join(@root, "#{@git_folder_name}/hooks/pre-commit")

  git_folder_exists = File.exists?(Path.dirname(@target))
  pre_commit_script_exists = fn file -> IO.read(file, :all) |> String.contains?("mix pre_commit") end

  IO.puts "Looking for #{@git_folder_name} at #{@target}"
  unless git_folder_exists, do: raise "[pre-commit] not a git repository !"
  with  {:ok, file}   <- File.open(@target, [:append, :read]),
        false         <- pre_commit_script_exists.(file),
        {:ok, _}      <- File.copy(@content, file),
        :ok           <- File.chmod(@target, 0o755) do
        :ok
  else
    true                      -> :ok # Hook pre_commit was already injected
    {:error, :eacces}         -> raise "Permission denied"
    {:error, :eagain}         -> raise "Resource temporarily unavailable (may be the same value as EWOULDBLOCK)"
    {:error, :ebadf}          -> raise "Bad file descriptor"
    {:error, :ebadmsg}        -> raise "Bad message"
    {:error, :ebusy}          -> raise "Device or resource busy"
    {:error, :edeadlk}        -> raise "Resource deadlock avoided"
    {:error, :edeadlock}      -> raise "On most architectures, a synonym for EDEADLK.  On some architectures (e.g., Linux MIPS, PowerPC, SPARC), it is a separate error code 'File locking deadlock error'"
    {:error, :edquot}         -> raise "Disk quota exceeded"
    {:error, :eexist}         -> raise "File exists"
    {:error, :efault}         -> raise "Bad address"
    {:error, :efbig}          -> raise "File too large"
    {:error, :eintr}          -> raise "Interrupted function cal"
    {:error, :einval}         -> raise "Invalid argument"
    {:error, :eio}            -> raise "Input/output error"
    {:error, :eisdir}         -> raise "Is a directory"
    {:error, :eloop}          -> raise "Too many levels of symbolic links"
    {:error, :emfile}         -> raise "Too many open files"
    {:error, :emlink}         -> raise "Too many links"
    {:error, :emultihop}      -> raise "Multihop attempted"
    {:error, :enametoolong}   -> raise "Filename too long"
    {:error, :enoent}         -> raise "No such file or directory"
    {:error, reason}          -> raise "#{reason}"
    err -> raise err
  end

    #         (ENOTSUP and EOPNOTSUPP have the same value on Linux, but
    #         (POSIX.1 says "STREAM ioctl(2) timeout".)
    #         In POSIX.1-2001 (XSI STREAMS option), this error was
    #         This error can occur for NFS and for other filesystems       ESTRPIPE
    #         Typically, this error results when a specified pathname
    #   ENFILE Too many open files in system
    #   ENOKEY Required key not available       ENOLCK No locks available
    #   ENOMSG No message of the desired type
    #   ENOSPC No space left on device
    #   ENOTTY Inappropriate I/O control operation
    #   EPROTO Protocol error
    #   ESTALE Stale file handle
    #   EXDEV  Improper link
    # .lib section in a.out corrupted
    # (POSIX.1, C99 The text shown here is the glibc error description; in
    # ).  Commonly caused by
    # ).  On Linux,
    # /proc/sys/fs/file-max limit (see proc(5)
    # access to this attribute; see xattr(7
    # Accessing a corrupted shared library       ELIBMAX
    # according to POSIX.1 these error values should be
    # Attempting to link in too many shared libraries       ELIBSCN
    # Block device required       ENOTCONN The socket is not connected
    # Cannot access a needed shared library       ELIBBAD
    # Cannot exec a shared library directly       ELNRANGE Link number out of range
    # described as "No message is available on the STREAM head read queue"       ENODEV No such device
    # distinct.)
    # does not exist, or one of the components in the directory
    # EADDRINUSE Address already in use
    # EADDRNOTAVAIL Address not available
    # EAFNOSUPPORT Address family not supported
    # EALREADY Connection already in progress
    # EBADE  Invalid exchange
    # EBADFD File descriptor in bad state
    # EBADR  Invalid request descriptor
    # EBADRQC Invalid request code
    # EBADSLT Invalid slot
    # ECANCELED Operation canceled
    # ECHILD No child processes
    # ECHRNG Channel number out of range
    # ECOMM  Communication error on send
    # ECONNABORTED Connection aborted
    # ECONNREFUSED Connection refused
    # ECONNRESET Connection reset
    # EDESTADDRREQ Destination address required
    # EDOM   Mathematics argument out of domain of function (POSIX.1,
    # EHOSTDOWN Host is down
    # EHOSTUNREACH Host is unreachable
    # EHWPOISON Memory page has hardware error
    # EIDRM  Identifier removed
    # EILSEQ Invalid or incomplete multibyte or wide character
    # EISCONN Socket is connected
    # EISNAM Is a named type file       EKEYEXPIRED
    # ELIBEXEC
    # EMEDIUMTYPE Wrong medium type
    # EMSGSIZE Message too long
    # ENETDOWN Network is down
    # ENETRESET Connection aborted by network
    # ENETUNREACH Network unreachable
    # ENOANO No anode       ENOBUFS
    # ENODATA
    # ENOLINK Link has been severed
    # ENOMEDIUM No medium found       ENOMEM Not enough space/cannot allocate memory
    # ENONET Machine is not on the network       ENOPKG Package not installed       ENOPROTOOPT Protocol not available
    # ENOSR  No STREAM resources (POSIX.1 (XSI STREAMS option)
    # ENOSTR Not a STREAM (POSIX.1 (XSI STREAMS option) ENOSYS Function not implemented
    # ENOTBLK
    # ENOTDIR Not a directory
    # ENOTEMPTY Directory not empty
    # ENOTRECOVERABLE
    # ENOTSOCK Not a socket
    # ENOTSUP Operation not supported
    # ENOTUNIQ Name not unique on network       ENXIO  No such device or address
    # EOPNOTSUPP Operation not supported on socket
    # EOVERFLOW Value too large to be stored in data type
    # EOWNERDEAD
    # EPFNOSUPPORT Protocol family not supported       EPIPE  Broken pipe
    # EPROTONOSUPPORT Protocol not supported
    # EPROTOTYPE Protocol wrong type for socket
    # ERANGE Result too large (POSIX.1, C99
    # EREMCHG
    # ESHUTDOWN Cannot send after transport endpoint shutdown       ESPIPE Invalid seek
    # ESOCKTNOSUPPORT Socket type not supported       ESRCH  No such process
    # ETIMEDOUT Connection timed out
    # ETOOMANYREFS
    # EUCLEAN
    # exceeding the RLIMIT_NOFILE resource limit described in
    # EXFULL Exchange full.
    # getrlimit(2).  Can also be caused by exceeding the limit specified in /proc/sys/fs/nr_open
    # Interrupted system call should be restarted       ERFKILL Operation not possible due to RF-kill       EROFS  Read-only filesystem
    # Key has been revoked       EL2HLT Level 2 halted       EL2NSYNC
    # Key has expired       EKEYREJECTED
    # Key was rejected by service       EKEYREVOKED
    # Level 2 not synchronized       EL3HLT Level 3 halted       EL3RST Level 3 reset       ELIBACC
    # No buffer space available (POSIX.1 (XSI STREAMS option)
    # Object is remote       EREMOTEIO
    # Operation would block (may be same value as EAGAIN)
    # Owner died (POSIX.1-2008 EPERM  Operation not permitted
    # pathname is a dangling symbolic link       ENOEXEC Exec format error
    # POSIX.1, this error is described as "Illegal byte sequence" EINPROGRESS Operation in progress
    # prefix of a pathname does not exist, or the specified
    # Protocol driver not attached       EUSERS Too many users       EWOULDBLOCK
    # Remote address changed       EREMOTE
    # Remote I/O error       ERESTART
    # State not recoverable (POSIX.1-2008
    # Streams pipe error       ETIME  Timer expired (POSIX.1 (XSI STREAMS option)
    # Structure needs cleaning       EUNATCH
    # The named attribute does not exist, or the process has no
    # this is probably a result of encountering the
    # Too many references: cannot splice       ETXTBSY Text file busy
end
