<?php

/**
 * Map Rate Viewer
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

define('MR_DBHOST', 'localhost');
define('MR_DBUSER', 'topno11_dwn');
define('MR_DBPASS', 'IVJ7MYIT');
define('MR_DBNAME', 'topno11_maprate');
define('MR_TABLENAME', 'map_ratings');
define('MR_THRESHOLD', 0);
define('MR_COLUMNS', 3);
define('MR_LEFTWIDTH', 200);
define('MR_RIGHTWIDTH', 100);

$sort = (isset($_GET['sort']) ? $_GET['sort'] : 'rating');
$reverse = (isset($_GET['reverse']) ? $_GET['reverse'] : 'no');

error_reporting(E_ALL & ~E_NOTICE);
 
 define('NO_REGISTER_GLOBALS', 1);
 define('THIS_SCRIPT', 'maprate');
 
 $phrasegroups = array();
 
 $specialtemplates = array();
 
 $globaltemplates = array(
 'maprate'
 );
 
 $actiontemplates = array();
 
 require_once('./global.php');
 
 eval('$navbar = "' . fetch_template('navbar') . '";');
 eval('print_output("' . fetch_template('maprate') . '");'); 
?>
<html>
<head>
    <style type="text/css">
        body {
            font-family: Trebuchet MS, Helvetica, sans-serif;
            margin-left: auto;
            margin-right: auto;
            width: <?php echo MR_COLUMNS * (MR_LEFTWIDTH + MR_RIGHTWIDTH); ?>;
        }

        div.title {
            margin: 0px;
            padding: 10px;
            color: white;
            background-color: #000066;;
        }
        div.title span.title {
            font-weight: bold;
            font-size: 18pt;
        }

        div.title a, a:visited, a:hover, a:link {
            color: white;
        }

        div.ratings {
        }

        table.map_rating {
            border: 2px solid DarkBlue;
            background-color: white;
            margin: 0;
        }

        table.map_rating span.map_name {
            font-weight: bold;
        }

        table.rating_graph {
            background-color: Lavender;
        }
        table.rating_graph td {
            font-size: 10pt;
        }
        table.rating_graph tr.bars td {
            vertical-align: bottom;
        }
        table.rating_graph tr.labels td {
            text-align: center;
            font-weight: bold;
            font-size: 8pt;
        }
        table.rating_graph div.rating_1 {
            background-color: #B80000;
        }
        table.rating_graph div.rating_2 {
            background-color: #B85800;
        }
        table.rating_graph div.rating_3 {
            background-color: #B89800;
        }
        table.rating_graph div.rating_4 {
            background-color: #99CC33;
        }
        table.rating_graph div.rating_5 {
            background-color: #33CC00;
        }
    </style>

</head>
<body>

<?php
class MapRating {
    public $name;
    public $num_ratings = 0;
    public $ratings = array(1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0);
    private $max_ratings = 0;

    function __construct($name) {
        $this->name = $name;
    }

    function add_rating($rating, $count) {
        if (!isset($this->ratings[$rating])) {
            throw new Exception('Invalid rating');
        }
        $this->ratings[$rating] += $count;
        $this->num_ratings += $count;
        $this->max_ratings = max($this->max_ratings, $count);
    }

    function get_graph($width = 300, $height = 100) {
        $row_bars = array();
        $row_labels = array();
        for ($i = 1; $i <= 5; $i++) {
            /* The weird comment inside the DIV is a fix for IE which renders
             * 20px height minimum without the comment */
            array_push($row_bars, 
                "\t\t<td width=\"20%\"><div class=\"rating_$i\" style=\"height: "
                .$this->get_rating_height($i, $height)
                ."\"><!-- --></div></td>\n"
            );
            array_push($row_labels, "\t\t<td>{$this->ratings[$i]}</td>\n");
        }

        
        return "<table class=\"rating_graph\" width=\"$width\" height=\"$height\">\n".
            "\t<tr class=\"bars\">\n".implode($row_bars)."\t</tr>\n".
            "\t<tr class=\"labels\" height=\"15\">\n".implode($row_labels)."\t</tr>\n".
            "</table>\n";
    }

    function get_average() {
        if ($this->num_ratings) {
            $rating_sum = 0;
            foreach (array_keys($this->ratings) as $key) {
                $rating_sum += $key * $this->ratings[$key];
            }
            return round($rating_sum / $this->num_ratings, 2);
        }
        else {
            return 0;
        }
    }

    private function get_rating_height($rating, $height) {
        if ($this->max_ratings) {
            return (int)($this->ratings[$rating] / $this->max_ratings * $height);
        }
        else {
            return $height;
        }
    }

    function get_num_ratings() {
        return "{$this->num_ratings} rating".($this->num_ratings == 1 ? '' : 's');
    }

    function get_table() {
        return "<table class=\"map_rating\">\n"
            ."\t<tr>\n"
            ."\t\t<td width=\"".MR_LEFTWIDTH."\"><span class=\"map_name\">{$this->name}</span><br/>{$this->get_average()} "
            ."({$this->get_num_ratings()})</td>\n"
            ."\t\t<td>{$this->get_graph(MR_RIGHTWIDTH, 30)}</td>\n"
            ."\t</tr>\n"
            ."</table>\n";
    }
}

class MapRatings {
    private $map_ratings;
    private $maps;
    private $db;

    function __construct() {
        $this->db = mysql_pconnect(MR_DBHOST, MR_DBUSER, MR_DBPASS);
        if (!$this->db|| !mysql_select_db(MR_DBNAME)) {
            throw new Exception('Could not establish connection to the database');
        }
        $this->populate_ratings();
    }

    private function populate_ratings() {
        $sort = 'ORDER BY rating DESC';
            $query = 'SELECT map, rating, COUNT(*) AS count FROM '.MR_TABLENAME.' GROUP BY map, rating';
            $result = mysql_query($query);

        $this->map_ratings = array();
        while ($row = mysql_fetch_object($result)) {
            if (!isset($this->map_ratings[$row->map])) {
                $this->map_ratings[$row->map] = new MapRating($row->map);
            }
            $this->map_ratings[$row->map]->add_rating($row->rating, $row->count);
        }

        foreach (array_keys($this->map_ratings) as $key) {
            if ($this->map_ratings[$key]->num_ratings < MR_THRESHOLD) {
                unset($this->map_ratings[$key]);
            }
        }

        $this->maps = array_keys($this->map_ratings);
    }

    function get_links($sort='name', $dir='no') {
        $sort_types = array('rating' => 'Rating', 'name' => 'Map Name', 'ratings' => 'Number of Ratings');

        $links = array();
        foreach (array_keys($sort_types) as $sort_type) {
            $link = '';
            if ($sort_type == $sort) {
                $link = "<strong>{$sort_types[$sort_type]}</strong>";
            }
            else {
                $link = "<a href=\"{$_SERVER['PHP_SELF']}?sort=$sort_type\">{$sort_types[$sort_type]}</a>";
            }
            array_push($links, $link);
        }

        return '<strong>Order By: </strong>'.implode(' | ', $links);
    }

    function set_sort($sort='rating', $dir='no') {
        $rating = array();
        $ratings = array();
        foreach (array_values($this->map_ratings) as $mr) {
            array_push($rating, $mr->get_average());
            array_push($ratings, $mr->num_ratings);
        }
        if ($sort == "name") {
            sort($this->maps);
        }
        else if ($sort == "rating") {
            array_multisort($rating, SORT_DESC, $this->maps);
        }
        else if ($sort == "ratings") {
            array_multisort($ratings, SORT_DESC, $this->maps);
        }

        if ($dir == "yes") {
            $this->maps = array_reverse($this->maps);
        }
    }

    function get_ratings_table() {
        ob_start();
        echo "<table>\n";
            $cell = 0;
            echo "\t<tr>\n";
        foreach ($this->maps as $map) {
            $mr = $this->map_ratings[$map];
            if (!$cell) {
                echo "\t</tr>\n";
                echo "\t<tr>\n";
            }
            echo "\t\t<td>".$mr->get_table()."</td>\n";
            $cell = ($cell + 1) % MR_COLUMNS;
        }
        while ($cell) {
            echo "\t\t<td>&nbsp;</td>\n";
            $cell = ($cell + 1) % MR_COLUMNS;
        }
        echo "\t</tr>\n";
        echo "</table>\n";

        $table = ob_get_contents();
        ob_end_clean();
        return $table;
    }
}

$mr = new MapRatings();
echo "<div class=\"title\"><span class=\"title\">Map Ratings</span><br/>";
echo "<span class=\"links\">".$mr->get_links($sort, $reverse)."</span></div>\n";
echo "<div class=\"ratings\">\n";
$mr->set_sort($sort, $reverse);
echo $mr->get_ratings_table();
echo "</div>\n";

?>
</body>
</html>