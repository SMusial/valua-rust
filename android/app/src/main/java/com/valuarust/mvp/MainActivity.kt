package com.valuarust.mvp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import uniffi.valua_edge.*

// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────
private val RustOrange   = Color(0xFFE8501A)
private val DecideGreen  = Color(0xFF2E7D32)
private val DecideYellow = Color(0xFFF9A825)
private val DecideRed    = Color(0xFFC62828)
private val SurfaceDark  = Color(0xFF1C1B1F)
private val CardBg       = Color(0xFF2A2930)

const val SESSION_LIMIT = 10

// ─────────────────────────────────────────────────────────────────────────────
// Activity
// ─────────────────────────────────────────────────────────────────────────────
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme(
                colorScheme = darkColorScheme(
                    primary   = RustOrange,
                    surface   = SurfaceDark,
                    background = SurfaceDark
                )
            ) {
                ValuaRustApp()
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root composable
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun ValuaRustApp() {
    // Fetch version string from Rust — if this renders the bridge is confirmed live
    val rustVersion = remember {
        runCatching { engineVersion() }.getOrElse { "bridge-error" }
    }

    var selectedCategory by remember { mutableStateOf<Category?>(null) }
    var valueInput       by remember { mutableStateOf("") }
    var scanResult       by remember { mutableStateOf<ScanResult?>(null) }
    var sessionCount     by remember { mutableStateOf(0) }
    var sessionComplete  by remember { mutableStateOf(false) }
    var errorMessage     by remember { mutableStateOf<String?>(null) }

    if (sessionComplete) {
        SessionCompleteScreen(sessionCount = sessionCount) {
            // Reset
            sessionCount    = 0
            sessionComplete = false
            scanResult      = null
            selectedCategory = null
            valueInput      = ""
        }
        return
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SurfaceDark)
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // ── Header ──────────────────────────────────────────────────────────
        HeaderSection(rustVersion = rustVersion)

        // ── Session counter ──────────────────────────────────────────────────
        SessionCounter(current = sessionCount, limit = SESSION_LIMIT)

        // ── Category picker ──────────────────────────────────────────────────
        CategoryPicker(
            selected = selectedCategory,
            onSelect = {
                selectedCategory = it
                scanResult       = null
                errorMessage     = null
            }
        )

        // ── Value input ───────────────────────────────────────────────────────
        ValueInputField(
            value    = valueInput,
            onChange = {
                valueInput   = it
                scanResult   = null
                errorMessage = null
            }
        )

        // ── Error message ─────────────────────────────────────────────────────
        errorMessage?.let {
            Text(
                text  = it,
                color = DecideRed,
                fontSize = 13.sp,
                modifier = Modifier.padding(horizontal = 4.dp)
            )
        }

        // ── Evaluate button ───────────────────────────────────────────────────
        EvaluateButton(
            enabled = selectedCategory != null && valueInput.isNotBlank()
        ) {
            val value = valueInput.toDoubleOrNull()
            when {
                value == null || value < 0 -> {
                    errorMessage = "Please enter a valid positive value in PLN."
                }
                else -> {
                    errorMessage = null
                    val input = ItemInput(
                        category           = selectedCategory!!,
                        estimatedValuePln  = value,
                        handlingCostOverride = null
                    )
                    scanResult = evaluateItem(input)
                    sessionCount++
                    if (sessionCount >= SESSION_LIMIT) {
                        sessionComplete = true
                    }
                }
            }
        }

        // ── Result card ───────────────────────────────────────────────────────
        AnimatedVisibility(
            visible = scanResult != null,
            enter   = fadeIn() + slideInVertically { it / 2 },
            exit    = fadeOut()
        ) {
            scanResult?.let { result ->
                DecisionCard(result = result)
            }
        }

        Spacer(modifier = Modifier.height(32.dp))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun HeaderSection(rustVersion: String) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text       = "ValuaRUST",
            fontSize   = 32.sp,
            fontWeight = FontWeight.ExtraBold,
            color      = RustOrange
        )
        Text(
            text     = "Estate Clearance Decision Engine",
            fontSize = 13.sp,
            color    = Color.Gray
        )
        Spacer(modifier = Modifier.height(4.dp))
        // Version string sourced from Rust — bridge confirmation
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = RustOrange.copy(alpha = 0.15f)
        ) {
            Text(
                text     = "v$rustVersion",
                fontSize = 11.sp,
                color    = RustOrange,
                modifier = Modifier.padding(horizontal = 10.dp, vertical = 3.dp)
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session counter
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun SessionCounter(current: Int, limit: Int) {
    val progress = current.toFloat() / limit.toFloat()
    val barColor = when {
        progress >= 0.8f -> DecideRed
        progress >= 0.5f -> DecideYellow
        else             -> DecideGreen
    }
    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text     = "Session items",
                fontSize = 13.sp,
                color    = Color.LightGray
            )
            Text(
                text       = "$current / $limit",
                fontSize   = 13.sp,
                fontWeight = FontWeight.Bold,
                color      = barColor
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
        LinearProgressIndicator(
            progress           = { progress },
            modifier           = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(RoundedCornerShape(3.dp)),
            color              = barColor,
            trackColor         = Color.DarkGray
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category picker
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun CategoryPicker(selected: Category?, onSelect: (Category) -> Unit) {
    val categories = listOf(
        Category.CLOTHING     to "👕 Clothing",
        Category.FURNITURE    to "🪑 Furniture",
        Category.BOOKS        to "📚 Books",
        Category.ELECTRONICS  to "📱 Electronics",
        Category.OTHER        to "📦 Other"
    )
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text       = "Select Category",
            fontSize   = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color      = Color.LightGray,
            modifier   = Modifier.padding(bottom = 8.dp)
        )
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            categories.take(3).forEach { (cat, label) ->
                CategoryChip(
                    label      = label,
                    isSelected = selected == cat,
                    onClick    = { onSelect(cat) },
                    modifier   = Modifier.weight(1f)
                )
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
        Row(
            modifier              = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            categories.drop(3).forEach { (cat, label) ->
                CategoryChip(
                    label      = label,
                    isSelected = selected == cat,
                    onClick    = { onSelect(cat) },
                    modifier   = Modifier.weight(1f)
                )
            }
            // Spacer to balance the row if odd number of chips
            if (categories.drop(3).size % 2 != 0) {
                Spacer(modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
fun CategoryChip(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        onClick      = onClick,
        modifier     = modifier,
        shape        = RoundedCornerShape(10.dp),
        color        = if (isSelected) RustOrange else CardBg,
        tonalElevation = if (isSelected) 0.dp else 2.dp
    ) {
        Text(
            text      = label,
            fontSize  = 12.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color     = if (isSelected) Color.White else Color.LightGray,
            textAlign = TextAlign.Center,
            modifier  = Modifier
                .fillMaxWidth()
                .padding(vertical = 10.dp, horizontal = 4.dp)
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Value input
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun ValueInputField(value: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value         = value,
        onValueChange = { onChange(it.filter { c -> c.isDigit() || c == '.' }) },
        label         = { Text("Estimated value (PLN)") },
        placeholder   = { Text("e.g. 100.00") },
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
        singleLine    = true,
        modifier      = Modifier.fillMaxWidth(),
        colors        = OutlinedTextFieldDefaults.colors(
            focusedBorderColor   = RustOrange,
            focusedLabelColor    = RustOrange,
            cursorColor          = RustOrange
        ),
        trailingIcon  = {
            Text(
                text     = "PLN",
                color    = Color.Gray,
                fontSize = 13.sp,
                modifier = Modifier.padding(end = 12.dp)
            )
        }
    )
}

// ─────────────────────────────────────────────────────────────────────────────
// Evaluate button
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun EvaluateButton(enabled: Boolean, onClick: () -> Unit) {
    Button(
        onClick  = onClick,
        enabled  = enabled,
        modifier = Modifier
            .fillMaxWidth()
            .height(52.dp),
        shape    = RoundedCornerShape(12.dp),
        colors   = ButtonDefaults.buttonColors(
            containerColor         = RustOrange,
            disabledContainerColor = RustOrange.copy(alpha = 0.3f)
        )
    ) {
        Text(
            text       = "⚡ Evaluate Item",
            fontSize   = 16.sp,
            fontWeight = FontWeight.Bold,
            color      = Color.White
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decision result card
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun DecisionCard(result: ScanResult) {
    val (actionLabel, actionColor, emoji) = when (val a = result.action) {
        is DecisionAction.Discard  -> Triple("DISCARD",          DecideRed,    "🔴")
        is DecisionAction.Bundle   -> Triple("BUNDLE",           DecideYellow, "🟡")
        is DecisionAction.SellOn   -> Triple("SELL on ${a.platform.name}", DecideGreen, "🟢")
        else                       -> Triple("UNKNOWN",          Color.Gray,   "⚪")
    }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape    = RoundedCornerShape(16.dp),
        color    = CardBg,
        tonalElevation = 4.dp
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // ── Decision badge ───────────────────────────────────────────────
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(text = emoji, fontSize = 24.sp)
                Spacer(modifier = Modifier.width(10.dp))
                Text(
                    text       = actionLabel,
                    fontSize   = 22.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color      = actionColor
                )
            }

            Divider(color = Color.DarkGray)

            // ── Metrics ───────────────────────────────────────────────────────
            MetricRow(
                label = "Expected net profit E[Z]",
                value = "%.2f PLN".format(result.expectedNetProfit),
                valueColor = if (result.expectedNetProfit > 0) DecideGreen else DecideRed
            )
            MetricRow(
                label = "Sale probability",
                value = "%.0f%%".format(result.saleProbability * 100.0),
                valueColor = Color.LightGray
            )
            MetricRow(
                label      = "Your 1% platform fee",
                value      = "%.2f PLN".format(result.platformFee),
                valueColor = RustOrange
            )

            Divider(color = Color.DarkGray)

            // ── Reason string from Rust ───────────────────────────────────────
            Text(
                text     = result.reason,
                fontSize = 12.sp,
                color    = Color.Gray,
                lineHeight = 16.sp
            )
        }
    }
}

@Composable
fun MetricRow(label: String, value: String, valueColor: Color) {
    Row(
        modifier              = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment     = Alignment.CenterVertically
    ) {
        Text(
            text     = label,
            fontSize = 13.sp,
            color    = Color.LightGray,
            modifier = Modifier.weight(1f)
        )
        Text(
            text       = value,
            fontSize   = 14.sp,
            fontWeight = FontWeight.Bold,
            color      = valueColor
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session complete screen
// ─────────────────────────────────────────────────────────────────────────────
@Composable
fun SessionCompleteScreen(sessionCount: Int, onReset: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(SurfaceDark)
            .padding(32.dp),
        verticalArrangement   = Arrangement.Center,
        horizontalAlignment   = Alignment.CenterHorizontally
    ) {
        Text(text = "✅", fontSize = 64.sp)
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text       = "Session Complete",
            fontSize   = 28.sp,
            fontWeight = FontWeight.ExtraBold,
            color      = Color.White,
            textAlign  = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text      = "$sessionCount items evaluated this session.",
            fontSize  = 15.sp,
            color     = Color.LightGray,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text      = "V1.0 limit: $SESSION_LIMIT items per session.\nCamera scanning and unlimited sessions coming in Phase 1.5.",
            fontSize  = 12.sp,
            color     = Color.Gray,
            textAlign = TextAlign.Center,
            lineHeight = 18.sp
        )
        Spacer(modifier = Modifier.height(32.dp))
        Button(
            onClick  = onReset,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape    = RoundedCornerShape(12.dp),
            colors   = ButtonDefaults.buttonColors(containerColor = RustOrange)
        ) {
            Text(
                text       = "Start New Session",
                fontSize   = 16.sp,
                fontWeight = FontWeight.Bold,
                color      = Color.White
            )
        }
    }
}
