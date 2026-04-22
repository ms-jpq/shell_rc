#!/usr/bin/env -S -- bash -Eeuo pipefail
       *> . || cobc -Wall -x "$0" -o "${T:="$(mktemp)"}" && exec -a "$0" -- "$T" "$@"
       >>SOURCE FORMAT FREE

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DL.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
       SELECT RUNF ASSIGN TO "tmp.txt".

       DATA DIVISION.
       FILE SECTION.
       FD RUNF.
       01 RUN PIC X(9999).

       WORKING-STORAGE SECTION.
       01 PTR POINTER.
       01 ENV-BIN PIC XXX VALUE "BIN".
       01 ENV-RUN PIC XXX VALUE "RUN".
       01 ENV-LEN PIC 9(8) BINARY.

       01 BIN PIC X(99).
       01 RUND PIC X(99).

       01 SH PIC X(9999).
       01 SPIT PIC X(8) VALUE ">tmp.txt".
       01 RETVAL PIC 999 VALUE 0.

       01 OSTYPE PIC X(99).
       01 OS-IDX PIC 99.

       01 REPO PIC X(37) VALUE "eclipse-che4z/che-che4z-lsp-for-cobol".
       01 VERSION PIC X(99).
       01 URI PIC X(999).

       01 NAIVE PIC X(99).

       LINKAGE SECTION.
       01 ENV PIC X(9999).

       PROCEDURE DIVISION.
           SET PTR TO ADDRESS OF ENV-BIN.
           CALL "getenv" USING BY VALUE PTR RETURNING PTR
           IF PTR = NULL THEN
             MOVE 1 TO RETURN-CODE
             EXIT PROGRAM
           ELSE
             SET ADDRESS OF ENV TO PTR
             MOVE 0 TO ENV-LEN
             INSPECT ENV TALLYING ENV-LEN
               FOR CHARACTERS BEFORE INITIAL X"00"
             MOVE ENV(1:ENV-LEN) TO BIN
           END-IF.

           SET PTR TO ADDRESS OF ENV-RUN.
           CALL "getenv" USING BY VALUE PTR RETURNING PTR
           IF PTR = NULL THEN
             MOVE 1 TO RETURN-CODE
             EXIT PROGRAM
           ELSE
             SET ADDRESS OF ENV TO PTR
             MOVE 0 TO ENV-LEN
             INSPECT ENV TALLYING ENV-LEN
               FOR CHARACTERS BEFORE INITIAL X"00"
             MOVE ENV(1:ENV-LEN) TO RUND
           END-IF.

           STRING RUND "/extension/server/native" DELIMITED BY " "
           INTO NAIVE.

           MOVE SPACES TO SH.
           MOVE SPACES TO RUN.

           STRING "bash -c 'printf -- %s $OSTYPE'"
           " " SPIT DELIMITED SIZE INTO SH.
           CALL "SYSTEM" USING SH RETURNING RETVAL.
           IF RETVAL NOT = 0
             MOVE RETVAL TO RETURN-CODE
             EXIT PROGRAM
           END-IF.
           OPEN INPUT RUNF.
           READ RUNF into OSTYPE.
           CLOSE RUNF.

           MOVE SPACES TO SH.
           MOVE SPACES TO RUN.

           STRING "gh-latest.sh" " . " REPO " " SPIT
           DELIMITED SIZE INTO SH.
           CALL "SYSTEM" USING SH RETURNING RETVAL.
           IF RETVAL NOT = 0
             MOVE RETVAL TO RETURN-CODE
             EXIT PROGRAM
           END-IF.
           OPEN INPUT RUNF.
           READ RUNF into VERSION.
           CLOSE RUNF.

           STRING "https://github.com/" REPO
           "/releases/latest/download/cobol-language-support"
           DELIMITED SIZE INTO URI.

           MOVE 0 TO OS-IDX.
           INSPECT OSTYPE TALLYING OS-IDX FOR LEADING "linux".
           IF OS-IDX = 1
             STRING URI "-linux-x64-" VERSION ".vsix"
             DELIMITED BY " " INTO URI
             STRING NAIVE "/server-*"
             DELIMITED BY " " INTO NAIVE
           END-IF.

           MOVE 0 TO OS-IDX.
           INSPECT OSTYPE TALLYING OS-IDX FOR LEADING "darwin".
           IF OS-IDX = 1
             STRING URI "-darwin-arm64-" VERSION ".vsix"
             DELIMITED BY " " INTO URI
             STRING NAIVE "/server-*"
             DELIMITED BY " " INTO NAIVE
           END-IF.

           MOVE 0 TO OS-IDX.
           INSPECT OSTYPE TALLYING OS-IDX FOR LEADING "msys".
           IF OS-IDX = 1
             STRING BIN ".exe" DELIMITED BY SIZE INTO BIN
             STRING URI "-win32-x64-" VERSION "-signed.vsix"
             DELIMITED BY " " INTO URI
             STRING NAIVE "/*"
             DELIMITED BY " " INTO NAIVE
           END-IF.

           MOVE SPACES TO SH.

           STRING "get.sh " URI
           " | unpack.sh "
           RUND DELIMITED BY SIZE INTO SH.
           CALL "SYSTEM" USING SH RETURNING RETVAL.
           IF RETVAL NOT = 0
             MOVE RETVAL TO RETURN-CODE
             EXIT PROGRAM
           END-IF.

           MOVE SPACES TO SH.

           STRING "install -v -b -- " NAIVE BIN
           DELIMITED BY SIZE INTO SH.
           CALL "SYSTEM" USING SH RETURNING RETVAL.
           IF RETVAL NOT = 0
             MOVE RETVAL TO RETURN-CODE
             EXIT PROGRAM
           END-IF.
