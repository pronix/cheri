/***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2007,2008 William N Dortch <bill.dortch@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 ***** END LICENSE BLOCK *****/

package org.cheri.swing.layout;

import java.awt.Component;
import java.util.ArrayList;
import java.util.List;


public class GridRow {
	
	ArrayList cells = new ArrayList();
	Object defaultConstraints;
	
	public GridRow() {}
		
	public GridRow(Object defaultConstraints) {
		this.defaultConstraints = defaultConstraints;
	}
	
	public void add(Component comp) {
		cells.add(new GridCell(comp));
	}
	
	public void add(Component comp, Object constraints) {
		cells.add(new GridCell(comp, constraints));
	}
	
	public Object getDefaultConstraints() {
		return defaultConstraints;
	}
	
	public void setDefaultConstraints(Object defaultConstraints) {
		this.defaultConstraints = defaultConstraints;
	}
	
	public List getCells() {
		return cells;
	}
	
	public static class GridCell {
		Component comp;
		Object constraints;
		
		public GridCell(Component comp) {
			this.comp = comp;
		}
		public GridCell(Component comp, Object constraints) {
			this.comp = comp;
			this.constraints = constraints;
		}
		public Component getComponent() {
			return comp;
		}
		public Object getConstraints() {
			return constraints;
		}
		public void setConstraints(Object constraints) {
			this.constraints = constraints;
		}
	}

}
