/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
/*
 * Copyright (C) 2011 Alexander Larsson <alexl@redhat.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
using Folks;

public class Contacts.ListPane : Frame {
  private Store contacts_store;
  private View contacts_view;
  public Entry filter_entry;
  private uint filter_entry_changed_id;
  private bool ignore_selection_change;
  private bool search_visible;

  public signal void selection_changed (Contact? contact);

  private void refilter () {
    string []? values;
    string str = filter_entry.get_text ();

    if (str.length == 0)
      values = null;
    else {
      str = Utils.canonicalize_for_search (str);
      values = str.split(" ");
    }

    contacts_view.set_filter_values (values);
    if (values == null)
      contacts_view.set_show_subset (View.Subset.MAIN);
    else
      contacts_view.set_show_subset (View.Subset.ALL_SEPARATED);
  }

  private bool filter_entry_changed_timeout () {
    filter_entry_changed_id = 0;
    refilter ();
    return false;
  }

  private void filter_entry_changed (Editable editable) {
    if (filter_entry_changed_id != 0)
      Source.remove (filter_entry_changed_id);

    filter_entry_changed_id = Timeout.add (300, filter_entry_changed_timeout);

    if (filter_entry.get_text () == "")
      filter_entry.set_icon_from_icon_name (EntryIconPosition.SECONDARY, "edit-find-symbolic");
    else
      filter_entry.set_icon_from_icon_name (EntryIconPosition.SECONDARY, "edit-clear-symbolic");
  }

  private void filter_entry_clear (EntryIconPosition position) {
    filter_entry.set_text ("");
  }

  public ListPane (Store contacts_store) {
    this.get_style_context ().add_class (STYLE_CLASS_SIDEBAR);
    this.contacts_store = contacts_store;
    this.contacts_view = new View (contacts_store);
    var toolbar = new Toolbar ();
    toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);
    toolbar.set_icon_size (IconSize.MENU);
    toolbar.set_vexpand (false);
    toolbar.set_hexpand (true);

    contacts_view.set_show_subset (View.Subset.MAIN);

    filter_entry = new Entry ();
    filter_entry.set_icon_from_icon_name (EntryIconPosition.SECONDARY, "edit-find-symbolic");
    filter_entry.changed.connect (filter_entry_changed);
    filter_entry.icon_press.connect (filter_entry_clear);

    var search_entry_item = new ToolItem ();
    search_entry_item.is_important = false;
    search_entry_item.set_expand (true);
    search_entry_item.add (filter_entry);
    toolbar.add (search_entry_item);

    this.set_size_request (315, -1);
    this.set_hexpand (false);

    var scrolled = new ScrolledWindow(null, null);
    scrolled.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
    scrolled.set_vexpand (true);
    scrolled.set_hexpand (true);
    scrolled.set_shadow_type (ShadowType.NONE);

    var grid = new Grid ();
    grid.set_orientation (Orientation.VERTICAL);
    this.add (grid);

    contacts_view.selection_changed.connect( (l, contact) => {
	if (!ignore_selection_change)
	  selection_changed (contact);
      });

    contacts_view.add_to_scrolled (scrolled);
    contacts_view.show_all ();
    scrolled.set_no_show_all (true);

    grid.add (toolbar);
    grid.add (scrolled);

    this.show_all ();

    scrolled.show ();
  }

  public void select_contact (Contact contact, bool ignore_change = false) {
    if (ignore_change)
      ignore_selection_change = true;
    contacts_view.select_contact (contact);
    ignore_selection_change = false;
  }
}
