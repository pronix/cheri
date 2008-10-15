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
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import javax.swing.JPanel;

import org.cheri.compat.JRubyVersionAdapter;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.RubySymbol;

public class GridTable extends JPanel {

    private static final int NOT_AN_INT = Integer.MIN_VALUE;
    private static final double NOT_A_DOUBLE = Double.MIN_VALUE;

    private static final int F_GRIDX       = 1;
    private static final int F_GRIDY       = 2;
    private static final int F_GRIDWIDTH   = 3;
    private static final int F_GRIDHEIGHT  = 4;
    private static final int F_WEIGHTX     = 5;
    private static final int F_WEIGHTY     = 6;
    private static final int F_IPADX       = 7;
    private static final int F_IPADY       = 8;
    private static final int F_FILL        = 9;
    private static final int F_ANCHOR      = 10;
    private static final int F_INSETS      = 11;
    // pseudo-fields provided for convenience and html-style specification
    private static final int F_PAD         = 12; // maps to ipadx, ipady
    private static final int F_VALIGN      = 13; // combined with anchor value
    private static final int F_CELLSPACING = 14; // maps to insets w/special handling
    
    
    private static final Map FIELDS = new HashMap(128,0.5f);
    
    static {
        FIELDS.put("gridx",       new Integer(F_GRIDX));
        FIELDS.put("gridy",       new Integer(F_GRIDY));
        FIELDS.put("gridwidth",   new Integer(F_GRIDWIDTH));
        FIELDS.put("gridheight",  new Integer(F_GRIDHEIGHT));
        FIELDS.put("weightx",     new Integer(F_WEIGHTX));
        FIELDS.put("weighty",     new Integer(F_WEIGHTY));
        FIELDS.put("ipadx",       new Integer(F_IPADX));
        FIELDS.put("ipady",       new Integer(F_IPADY));
        FIELDS.put("fill",        new Integer(F_FILL));
        FIELDS.put("anchor",      new Integer(F_ANCHOR));
        FIELDS.put("insets",      new Integer(F_INSETS));
        FIELDS.put("pad",         new Integer(F_PAD));
        FIELDS.put("valign",      new Integer(F_VALIGN));
        FIELDS.put("cellspacing", new Integer(F_CELLSPACING));

        String[][] aliases = {
            {"x", "gridx"}, {"gx", "gridx"}, {"y", "gridy"}, {"gy", "gridy"},
            {"w", "gridwidth"}, {"gw", "gridwidth"}, {"cols", "gridwidth"}, {"colspan", "gridwidth"},
            {"h", "gridheight"}, {"gh", "gridheight"}, {"rows", "gridheight"}, {"rowspan", "gridheight"},
            {"wx", "weightx"}, {"wy", "weighty"}, {"px", "ipadx"}, {"py", "ipady"},
            {"f", "fill"}, {"a", "anchor"}, {"align", "anchor"}, {"va", "valign"},
            {"i", "insets"}, {"p", "pad"}, {"ipad", "pad"}, {"cellpadding", "pad"},
        };
        for (int i = aliases.length; --i >= 0; ) {
            String[] mapping = aliases[i];
            Object value;
            if ((value = FIELDS.get(mapping[1])) != null && FIELDS.get(mapping[0]) == null) {
                FIELDS.put(mapping[0], value);
            }
        }
    }


    private static final Map SYMS = new HashMap(128,0.5f);

    static {
        try {
            Field[] fields = GridBagConstraints.class.getFields();
            for (int i = fields.length; --i >= 0; ) {
                Field field = fields[i];
                int mods = field.getModifiers();
                if (Modifier.isPublic(mods) && Modifier.isStatic(mods)) {
                        SYMS.put(field.getName().toLowerCase(), field.get(null));
                }
            }
        } catch (Exception e) {
            System.err.println("Cheri: error initializing GridTable class: " + e.getMessage());
        }

        String[][] aliases = {
            {"n", "north"}, {"s", "south"}, {"e", "east"}, {"w", "west"}, {"c", "center"},
            {"ne", "northeast"}, {"se", "southeast"}, {"nw", "northwest"}, {"sw", "southwest"},
            {"top", "north"}, {"bottom", "south"}, {"right", "east"}, {"left", "west"}, {"middle", "center"},
            {"h", "horizontal"}, {"v", "vertical"}, {"rel", "relative"}, {"rem", "remainder"},
            // TODO: baseline (1.6) sym aliases
        };
        for (int i = aliases.length; --i >= 0; ) {
            String[] mapping = aliases[i];
            Object value;
            if ((value = SYMS.get(mapping[1])) != null && SYMS.get(mapping[0]) == null) {
                SYMS.put(mapping[0], value);
            }
        }
    }


    //
    // instance fields
    //

    private final GridBagConstraints defaultConstraints = new GridBagConstraints();
    private final GridBagLayout layout = new GridBagLayout();

    private int nextRow = 0;
    private int maxCol = 0;
    private int[] filledCols = new int[32];

    public GridTable() {
       setLayout(layout);
    }
    
    // override Container#add(Component,Object)
    // not normally called by Cheri builder code, provided in case
    // user chooses to manually manage gridx/gridy, etc. (instead of using GridRow)
    public void add(Component comp, Object constraints) {
    	if (constraints instanceof RubyHash) {
    		GridBagConstraints c = (GridBagConstraints)defaultConstraints.clone();
    		setHashedValues(c, (RubyHash)constraints);
    		constraints = c;
    	}
    	super.add(comp, constraints);
    }
    
    // override Container#add(Component,Object,int)
    // not normally called by Cheri builder code, provided in case
    // user chooses to manually manage gridx/gridy, etc. (instead of using GridRow)
    public void add(Component comp, Object constraints, int index) {
    	if (constraints instanceof RubyHash) {
    		GridBagConstraints c = (GridBagConstraints)defaultConstraints.clone();
    		setHashedValues(c, (RubyHash)constraints);
    		constraints = c;
    	}
    	super.add(comp, constraints, index);
    }
    
    public void addRow(GridRow gridRow) {
    	Object rowDefaultsObj;
    	GridBagConstraints rowDefaults;
    	if ((rowDefaultsObj = gridRow.defaultConstraints) != null) {
    		if (rowDefaultsObj instanceof RubyHash) {
    			rowDefaults = (GridBagConstraints)this.defaultConstraints.clone();
    			setHashedValues(rowDefaults, (RubyHash)rowDefaultsObj);
    		} else if (rowDefaultsObj instanceof GridBagConstraints) {
    			rowDefaults = (GridBagConstraints)rowDefaultsObj;
    		} else {
    			rowDefaults = this.defaultConstraints;
    		}
    	} else {
    		rowDefaults = this.defaultConstraints;
    	}
    	rowDefaults.gridy = nextRow++;
    	int col = 0;
    	ArrayList cells;
    	if ((cells = gridRow.cells) == null || cells.size() == 0) {
    		advanceCols();
    		return;
    	}
    	for (Iterator iter = cells.iterator(); iter.hasNext(); ) {
    		GridRow.GridCell cell = (GridRow.GridCell)iter.next();
    		Component comp;
    		if ((comp = cell.comp) == null) continue;
    		Object constObj;
    		GridBagConstraints c;
    		if ((constObj = cell.constraints) != null) {
    			if (constObj instanceof RubyHash) {
        			c = (GridBagConstraints)rowDefaults.clone();
        			setHashedValues(c, (RubyHash)constObj);
    			} else if (constObj instanceof GridBagConstraints) {
    				c = (GridBagConstraints)constObj;
    			} else {
        			c = (GridBagConstraints)rowDefaults.clone();
    			}
    		} else {
    			c = (GridBagConstraints)rowDefaults.clone();
    		}
    		int ccol;
    		if ((ccol = c.gridx) < 0) {
    			// find the next empty column
    			for ( ; isColFilled(col); col++);
    			ccol = c.gridx = col;
    		} else {
    			col = ccol;
    		}
    		int w = Math.max(c.gridwidth, -1);
    		c.gridwidth = w; // correct any values < -1
    		int h = Math.max(c.gridheight, -1);
    		c.gridheight = h; // correct any values < -1
    		int nextcol;
    		if (w <= 0) {
    			nextcol = Math.max(col,maxCol) + 1 + w;
    		} else {
    			nextcol = col + w;
    		}
    		if (h <= 0)
    			h--; // map to our usage, rel = -2, rem = -1
    		int lastcol = nextcol - 1;
    		setColsFilled(col, lastcol, h);
    		col = nextcol;
    		if (maxCol < lastcol)
    			maxCol = lastcol;
    		
    		super.add(comp, c);
    		
    	}
    	advanceCols();
    }
    
    private boolean isColFilled(int col) {
    	return col < filledCols.length && filledCols[col] != 0;
    }
    
    private void setColsFilled(int first, int last, int rows) {
    	if (last > maxCol) maxCol = last;
    	if (last > filledCols.length) {
    		int newSize = filledCols.length << 1;
    		while (newSize <= last) {
    			newSize <<= 1;
    		}
    		int[] newCols = new int[newSize];
    		System.arraycopy(filledCols, 0, newCols, 0, filledCols.length);
    		filledCols = newCols;
    	}
    	for (int i = first; i <= last; i++) {
    		filledCols[i] = rows;
    	}
    }
    
    private void advanceCols() {
    	int[] cols = filledCols;
    	for (int i = maxCol; i >= 0; i--) {
    		if (cols[i] > 0) --cols[i];
    	}
    }

    public GridBagConstraints getDefaults() {
        return defaultConstraints;
    }
    
    
    public void setDefaults(Object defaults) {
        if (defaults instanceof RubyHash) {
            setHashedValues(defaultConstraints, (RubyHash)defaults);
        } else if (defaults instanceof RubyArray) {
            // TODO: shorthand syntax (list of constant syms; field inferred;
        	// may have hash as last arg)
        }
    }
    
    static void setHashedValues(GridBagConstraints c, RubyHash hash) {
        Ruby runtime = hash.getRuntime();
        JRubyVersionAdapter adapter = JRubyVersionAdapter.getAdapter();
        Object anchor = null;
        Object valign = null;
        for (Iterator iter = hash.entrySet().iterator(); iter.hasNext(); ) {
            Map.Entry entry = (Map.Entry)iter.next();
            String fieldName = adapter.getAsSymbolString(runtime, entry.getKey()).toLowerCase();
            Object value = entry.getValue();
            if (value instanceof RubySymbol) {
                value = adapter.getAsSymbolString(runtime, value);
            }
            if (value instanceof String) {
                Object mapped;
                if ((mapped = SYMS.get(((String)value).toLowerCase())) != null) {
                    value = mapped;
                }
            }
            Integer fieldId;
            if ((fieldId = (Integer)FIELDS.get(fieldName)) != null) {
            	int fid;
            	switch(fid = fieldId.intValue()) {
            	case F_ANCHOR:
            		anchor = value;
            		break;
            	case F_VALIGN:
            		valign = value;
            		break;
            	default:
            		setValue(c, fid, value);
            		break;
            	}
            }
        }
        if (anchor != null || valign != null) {
        	if (valign == null) {
        		int val;
        		if ((val = intValue(anchor)) != NOT_AN_INT) {
        			c.anchor = val;
        		}
        	} else if (anchor == null) {
        		int val;
        		if ((val = intValue(anchor)) != NOT_AN_INT) {
        			// FIXME: should probably merge with current anchor val as below
        			c.anchor = val;
        		}
        	} else {
        		// TODO: break out x/y components, map back to anchor type
        	}
        }
    }
    
    static void setValue(GridBagConstraints c, String fieldName, Object value) {
        Integer fieldId;
        if ((fieldId = (Integer)FIELDS.get(fieldName)) != null) {
        	setValue(c, fieldId.intValue(), value);
        }
    }
    
    static void setValue(GridBagConstraints c, int fieldId, Object value) {
        int ival;
        double dval;
        
        switch(fieldId) {
        case F_GRIDX:
            if ((ival = intValue(value)) != NOT_AN_INT)
                c.gridx = ival;
            return;
        case F_GRIDY:
            if ((ival = intValue(value)) != NOT_AN_INT)
                c.gridy = ival;
            return;
        case F_GRIDWIDTH:
            if ((ival = intValue(value)) != NOT_AN_INT)
                c.gridwidth = ival;
            return;
        case F_GRIDHEIGHT:
            if ((ival = intValue(value)) != NOT_AN_INT)
                c.gridheight = ival;
            return;
        case F_WEIGHTX:
            if ((dval = doubleValue(value)) != NOT_A_DOUBLE)
                c.weightx = dval;
            return;
        case F_WEIGHTY:
            if ((dval = doubleValue(value)) != NOT_A_DOUBLE)
                c.weighty = dval;
            return;
        case F_IPADX:
            if ((ival = intValue(value)) != NOT_AN_INT)
                c.ipadx = ival;
            return;
        case F_IPADY:
            if ((ival = intValue(value)) != NOT_AN_INT)
                c.ipady = ival;
            return;
        case F_FILL:
            if ((ival = intValue(value)) != NOT_AN_INT)
                c.fill = ival;
            return;
        case F_ANCHOR:
            if ((ival = intValue(value)) != NOT_AN_INT)
                c.anchor = ival;
            return;
        case F_INSETS:
        case F_CELLSPACING:
        	setInsets(c, fieldId, value);
        	return;
        case F_PAD:
        	setPadding(c, fieldId, value);
        	return;
        }
    }
    
    static void setInsets(GridBagConstraints c, int fieldId, Object value) {
        if (value == null) {
            c.insets = new Insets(0,0,0,0);
        } else if (value instanceof Number ||
                (value instanceof String && (value = integerValue(value)) != null)) {
            int val = ((Number)value).intValue();
            if (fieldId == F_CELLSPACING) {
                // "cellspacing" needs special(er) handling
                //  - should only be single value, not array
                //  - we'll fake it by adding only to right and bottom
            	// FIXME: does this make any sense? better way?
                c.insets = new Insets(0,0,val,val);
            } else {
                c.insets = new Insets(val,val,val,val);
            }
        } else if (value instanceof RubyArray) {
        	int[] values = rubyArrayToIntArray((RubyArray)value, 4);
        	switch(values.length) {
        	case 0:
        		c.insets = new Insets(0,0,0,0);
        		break;
        	case 1: {
        		int val = values[0];
        		c.insets = new Insets(val,val,val,val);
        		break;
        	}
        	case 2: {
        		int ix = values[0];
        		int iy = values[1];
        		c.insets = new Insets(iy,ix,iy,ix);
        		break;
        	}
        	case 3: {
        		c.insets = new Insets(values[0],values[1],values[2],values[1]);
        		break;
        	}
        	case 4:
        		c.insets = new Insets(values[0],values[1],values[2],values[3]);
        		break;
        	}
        } else {
            System.out.println("got something else:" +value.getClass().getName());
        }
    }

    static void setPadding(GridBagConstraints c, int fieldId, Object value) {
        if (value == null) {
            c.ipadx = 0;
            c.ipady = 0;
        } else if (value instanceof Number ||
                (value instanceof String && (value = integerValue(value)) != null)) {
            int val = ((Number)value).intValue();
            c.ipadx = val;
            c.ipady = val;
        } else if (value instanceof RubyArray) {
        	int[] values = rubyArrayToIntArray((RubyArray)value, 2);
        	switch(values.length) {
        	case 0:
        		c.ipadx = 0;
        		c.ipady = 0;
        		break;
        	case 1:
        		c.ipadx = values[0];
        		c.ipady = values[0];
        		break;
        	case 2:
        		c.ipadx = values[0];
        		c.ipady = values[1];
        	}
        } else {
            System.out.println("got something else:" +value.getClass().getName());
        }
    }

    private static Integer integerValue(Object arg) {
        if (arg instanceof Integer) {
            return (Integer)arg;
        } else if (arg instanceof Number) {
            return new Integer(((Number)arg).intValue());
        } else if (arg instanceof String) {
            try {
                return Integer.valueOf((String)arg);
            } catch (Exception e) {}
            try {
                return new Integer(Double.valueOf((String)arg).intValue());
            } catch (Exception e) {}
        }
        return null;
    }
    
    private static int intValue(Object arg) {
    	if (arg instanceof Number) {
    		return ((Number)arg).intValue();
    	} else if (arg instanceof String) {
    		try {
    			return Integer.parseInt((String)arg);
    		} catch (Exception e) {}
    		try {
    			return (int)Double.parseDouble((String)arg);
    		} catch (Exception e) {}
    	}
    	return NOT_AN_INT;
    }

    private static double doubleValue(Object arg) {
    	if (arg instanceof Number) {
    		return ((Number)arg).doubleValue();
        } else if (arg instanceof String) {
            try {
                return Double.parseDouble((String)arg);
            } catch (Exception e) {}
        }
        return NOT_A_DOUBLE;
    }

    private static int[] rubyArrayToIntArray(RubyArray array, int maxlen) {
        Object[] values = array.toArray();
        int len = Math.min(values.length, maxlen);
        int[] ints = new int[len];
        for (int i = len; --i >= 0; ) {
        	int val;
        	if ((val = intValue(values[i])) != NOT_AN_INT) {
        		ints[i] = val;
        	}
        }
        return ints;
    }

}
