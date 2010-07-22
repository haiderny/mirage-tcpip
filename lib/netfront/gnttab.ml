(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Lwt

type r = int (* Grant ref *)

external gnttab_init : unit -> unit = "caml_gnttab_init"
external gnttab_fini : unit -> unit = "caml_gnttab_fini"
external gnttab_nr_entries : unit -> int = "caml_gnttab_nr_entries"
external gnttab_nr_reserved : unit -> int = "caml_gnttab_reserved"

let free_list = Queue.create ()
let free_list_condition = Lwt_condition.create ()

let put_free_entry r =
    Queue.push r free_list;
    Lwt_condition.signal free_list_condition ()

let rec get_free_entry () =
    match Queue.is_empty free_list with
    | true ->
        Lwt_condition.wait free_list_condition >>
        get_free_entry ()
    | false ->
        return (Queue.pop free_list)

let to_string (r:r) = string_of_int r

let init () =
    for i = gnttab_nr_reserved () to gnttab_nr_entries () - 1 do
        put_free_entry i
    done;
    gnttab_init ()

