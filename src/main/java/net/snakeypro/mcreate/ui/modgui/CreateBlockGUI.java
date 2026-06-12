package net.snakeypro.mcreate.ui.modgui;

import net.mcreator.blockly.data.Dependency;
import net.mcreator.element.parts.TabEntry;
import net.mcreator.element.types.interfaces.IBlockWithBoundingBox;
import net.mcreator.minecraft.ElementUtil;
import net.mcreator.ui.MCreator;
import net.mcreator.ui.component.util.ComponentUtils;
import net.mcreator.ui.component.util.PanelUtils;
import net.mcreator.ui.dialogs.TypedTextureSelectorDialog;
import net.mcreator.ui.help.IHelpContext;
import net.mcreator.ui.init.L10N;
import net.mcreator.ui.minecraft.*;
import net.mcreator.ui.minecraft.boundingboxes.JBoundingBoxList;
import net.mcreator.ui.modgui.ModElementGUI;
import net.mcreator.ui.procedure.AbstractProcedureSelector;
import net.mcreator.ui.procedure.NumberProcedureSelector;
import net.mcreator.ui.procedure.ProcedureSelector;
import net.mcreator.ui.validation.AggregatedValidationResult;
import net.mcreator.ui.validation.ValidationGroup;
import net.mcreator.ui.validation.component.VTextField;
import net.mcreator.ui.validation.validators.TextFieldValidator;
import net.mcreator.ui.validation.validators.TileHolderValidator;
import net.mcreator.ui.workspace.resources.TextureType;
import net.mcreator.workspace.elements.ModElement;
import net.snakeypro.mcreate.element.types.CreateBlock;
import net.snakeypro.mcreate.ui.component.*;

import javax.annotation.Nonnull;
import javax.swing.*;
import javax.swing.border.TitledBorder;
import java.awt.*;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Full dedicated editor GUI for the Create Mod Block element type.
 * Provides tabs: Visual, Block Properties, Create Kinetics, Shafts, Cogs,
 * Visual Boxes, Rotating Visuals, Events, Redstone/Links, Advanced.
 */
public class CreateBlockGUI extends ModElementGUI<CreateBlock> {

    // ── Validation ────────────────────────────────────────────────────────────
    private final ValidationGroup page1group = new ValidationGroup();
    private final ValidationGroup page2group = new ValidationGroup();

    // ── Tab 1: Visual ─────────────────────────────────────────────────────────
    private TextureSelectionButton texture;
    private TextureSelectionButton textureTop;
    private TextureSelectionButton textureLeft;
    private TextureSelectionButton textureFront;
    private TextureSelectionButton textureRight;
    private TextureSelectionButton textureBack;
    private TextureSelectionButton itemTexture;
    private final JComboBox<String> transparencyType = new JComboBox<>(
            new String[]{ "SOLID", "CUTOUT", "CUTOUT_MIPPED", "TRANSLUCENT" });
    private final JCheckBox hasTransparency = L10N.checkbox("elementgui.common.enable");
    private final JComboBox<String> rotationMode = new JComboBox<>(
            new String[]{ "No rotation", "Y axis (S/W/N/E) from player", "All faces from player",
                    "Y axis (S/W/N/E) from face", "All faces from face", "Log (X/Y/Z)" });
    private final JCheckBox emissiveRendering = L10N.checkbox("elementgui.common.enable");

    // ── Tab 2: Block Properties ───────────────────────────────────────────────
    private final VTextField name = new VTextField(20);
    private final JSpinner hardness = new JSpinner(new SpinnerNumberModel(1.0, -1.0, 64000.0, 0.05));
    private final JSpinner resistance = new JSpinner(new SpinnerNumberModel(10.0, 0.0, 2.0e9, 0.5));
    private NumberProcedureSelector luminance;
    private final JSpinner lightOpacity = new JSpinner(new SpinnerNumberModel(15, 0, 15, 1));
    private final JCheckBox hasGravity = L10N.checkbox("elementgui.common.enable");
    private final JCheckBox isWaterloggable = L10N.checkbox("elementgui.common.enable");
    private final JCheckBox unbreakable = L10N.checkbox("elementgui.common.enable");
    private final JCheckBox isReplaceable = L10N.checkbox("elementgui.common.enable");
    private TabListField creativeTabs;
    private final JComboBox<String> destroyTool = new JComboBox<>(
            new String[]{ "Not specified", "pickaxe", "axe", "shovel", "hoe" });
    private final JComboBox<String> vanillaToolTier = new JComboBox<>(
            new String[]{ "NONE", "STONE", "IRON", "DIAMOND" });
    private final JCheckBox requiresCorrectTool = L10N.checkbox("elementgui.common.enable");
    private final JCheckBox canProvidePower = L10N.checkbox("elementgui.common.enable");
    private NumberProcedureSelector emittedRedstonePower;
    private JBoundingBoxList boundingBoxList;
    private MCItemHolder customDrop;
    private final JSpinner dropAmount = new JSpinner(new SpinnerNumberModel(1, 0, 64, 1));
    private final JCheckBox useLootTableForDrops = L10N.checkbox("elementgui.common.use_table_loot_drops");

    // ── Tab 3: Create Kinetics ────────────────────────────────────────────────
    private final JComboBox<String> kineticRole = new JComboBox<>(
            new String[]{ "CONSUMER", "GENERATOR", "NEUTRAL", "CONFIGURABLE" });
    private final JComboBox<String> createFacingType = new JComboBox<>(
            new String[]{ "HORIZONTAL_FACING", "ALL_FACES", "AXIS" });
    private final JSpinner defaultStressImpact = new JSpinner(new SpinnerNumberModel(4.0, 0.0, 100000.0, 0.5));
    private NumberProcedureSelector stressImpactProcedure;
    private final JSpinner defaultCapacity = new JSpinner(new SpinnerNumberModel(256.0, 0.0, 1e9, 8.0));
    private NumberProcedureSelector capacityProcedure;
    private final JSpinner defaultGeneratedSpeed = new JSpinner(new SpinnerNumberModel(16.0, 0.0, 10000.0, 1.0));
    private NumberProcedureSelector generatedSpeedProcedure;
    private final JCheckBox enableKineticTick = new JCheckBox("Enable kinetic tick events");
    private final JCheckBox enableGoggles = new JCheckBox("Enable goggle tooltip");

    // ── Tab 4-7: List editors ─────────────────────────────────────────────────
    private JShaftList shaftList;
    private JCogList cogList;
    private JVisualBoxList visualBoxList;
    private JRotatingVisualList rotatingVisualList;

    // ── Tab 8: Events ─────────────────────────────────────────────────────────
    private ProcedureSelector onKineticTick;
    private ProcedureSelector onKineticLazyTick;
    private ProcedureSelector onGoggleTooltip;
    private ProcedureSelector onBlockAdded;
    private ProcedureSelector onNeighbourBlockChanges;
    private ProcedureSelector onTickUpdate;
    private ProcedureSelector onDestroyedByPlayer;
    private ProcedureSelector onDestroyedByExplosion;
    private ProcedureSelector onEntityCollides;
    private ProcedureSelector onEntityWalksOn;
    private ProcedureSelector onRightClicked;

    // ── Tab 9: Redstone / Links ───────────────────────────────────────────────
    private ProcedureSelector onRedstoneOn;
    private ProcedureSelector onRedstoneOff;
    private final JCheckBox enableRedstoneLink = new JCheckBox("Enable Create redstone link");
    private final JComboBox<String> redstoneLinkBehavior = new JComboBox<>(
            new String[]{ "RECEIVER", "TRANSMITTER", "BOTH" });
    private ProcedureSelector onRedstoneLinkReceive;
    private NumberProcedureSelector redstoneLinkOutputProcedure;

    // ── Tab 10: Advanced (Inventory + FE) ────────────────────────────────────
    private final JCheckBox hasInventory = L10N.checkbox("elementgui.block.has_inventory");
    private final JSpinner inventorySize = new JSpinner(new SpinnerNumberModel(9, 1, 256, 1));
    private final JSpinner inventoryStackSize = new JSpinner(new SpinnerNumberModel(64, 1, 1024, 1));
    private final JCheckBox inventoryDropWhenDestroyed = L10N.checkbox("elementgui.common.enable");
    private final JCheckBox hasEnergyStorage = L10N.checkbox("elementgui.block.enable_energy_storage");
    private final JSpinner energyInitial = new JSpinner(new SpinnerNumberModel(0, 0, Integer.MAX_VALUE, 1));
    private final JSpinner energyCapacity = new JSpinner(new SpinnerNumberModel(400000, 0, Integer.MAX_VALUE, 1));
    private final JSpinner energyMaxReceive = new JSpinner(new SpinnerNumberModel(200, 0, Integer.MAX_VALUE, 1));
    private final JSpinner energyMaxExtract = new JSpinner(new SpinnerNumberModel(200, 0, Integer.MAX_VALUE, 1));

    public CreateBlockGUI(MCreator mcreator, ModElement modElement, boolean editingMode) {
        super(mcreator, modElement, editingMode);
        initGUI();
        super.finalizeGUI();
    }

    @Override
    protected void initGUI() {
        // Lazy-initialized fields that need mcreator
        creativeTabs = new TabListField(mcreator);
        customDrop = new MCItemHolder(mcreator, ElementUtil::loadBlocksAndItems);
        boundingBoxList = new JBoundingBoxList(mcreator, this, null);
        shaftList = new JShaftList(mcreator, IHelpContext.NONE);
        cogList = new JCogList(mcreator, IHelpContext.NONE);
        visualBoxList = new JVisualBoxList(mcreator, IHelpContext.NONE);
        rotatingVisualList = new JRotatingVisualList(mcreator, IHelpContext.NONE);

        // ── Procedure selectors ──────────────────────────────────────────────
        // NumberProcedure: (IHelpContext, MCreator, JSpinner, Dependency.fromString)
        luminance = new NumberProcedureSelector(
                (IHelpContext) null, mcreator,
                new JSpinner(new SpinnerNumberModel(0, 0, 15, 1)),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        emittedRedstonePower = new NumberProcedureSelector(
                (IHelpContext) null, mcreator,
                new JSpinner(new SpinnerNumberModel(0, 0, 15, 1)),
                Dependency.fromString("x:number/y:number/z:number/world:world/direction:direction/blockstate:blockstate"));

        stressImpactProcedure = new NumberProcedureSelector(
                (IHelpContext) null, mcreator,
                new JSpinner(new SpinnerNumberModel(4.0, 0.0, 100000.0, 0.5)),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        capacityProcedure = new NumberProcedureSelector(
                (IHelpContext) null, mcreator,
                new JSpinner(new SpinnerNumberModel(256.0, 0.0, 1e9, 8.0)),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        generatedSpeedProcedure = new NumberProcedureSelector(
                (IHelpContext) null, mcreator,
                new JSpinner(new SpinnerNumberModel(16.0, 0.0, 10000.0, 1.0)),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        redstoneLinkOutputProcedure = new NumberProcedureSelector(
                (IHelpContext) null, mcreator,
                new JSpinner(new SpinnerNumberModel(0, 0, 15, 1)),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        // Standard block event procedure selectors
        onBlockAdded = new ProcedureSelector(
                withEntry("block/when_added"), mcreator,
                L10N.t("elementgui.block.event_on_block_added"),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate/oldState:blockstate/moving:logic"));

        onNeighbourBlockChanges = new ProcedureSelector(
                withEntry("block/when_neighbour_changes"), mcreator,
                L10N.t("elementgui.common.event_on_neighbour_block_changes"),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        onTickUpdate = new ProcedureSelector(
                withEntry("block/update_tick"), mcreator,
                L10N.t("elementgui.common.event_on_update_tick"),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        onDestroyedByPlayer = new ProcedureSelector(
                withEntry("block/when_destroyed_player"), mcreator,
                L10N.t("elementgui.block.event_on_block_destroyed_by_player"),
                Dependency.fromString("x:number/y:number/z:number/world:world/entity:entity/blockstate:blockstate"));

        onDestroyedByExplosion = new ProcedureSelector(
                withEntry("block/when_destroyed_explosion"), mcreator,
                L10N.t("elementgui.block.event_on_block_destroyed_by_explosion"),
                Dependency.fromString("x:number/y:number/z:number/world:world"));

        onEntityCollides = new ProcedureSelector(
                withEntry("block/when_entity_collides"), mcreator,
                L10N.t("elementgui.block.event_on_entity_collides"),
                Dependency.fromString("x:number/y:number/z:number/world:world/entity:entity/blockstate:blockstate"));

        onEntityWalksOn = new ProcedureSelector(
                withEntry("block/when_entity_walks_on"), mcreator,
                L10N.t("elementgui.block.event_on_entity_walks_on"),
                Dependency.fromString("x:number/y:number/z:number/world:world/entity:entity/blockstate:blockstate"));

        onRightClicked = new ProcedureSelector(
                withEntry("block/when_right_clicked"), mcreator,
                L10N.t("elementgui.block.event_on_right_clicked"),
                Dependency.fromString("x:number/y:number/z:number/world:world/entity:entity/direction:direction/blockstate:blockstate/hitX:number/hitY:number/hitZ:number"));

        onRedstoneOn = new ProcedureSelector(
                withEntry("block/on_redstone_on"), mcreator,
                L10N.t("elementgui.block.event_on_redstone_on"),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        onRedstoneOff = new ProcedureSelector(
                withEntry("block/on_redstone_off"), mcreator,
                L10N.t("elementgui.block.event_on_redstone_off"),
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate"));

        // Create-specific procedure selectors
        onKineticTick = new ProcedureSelector(
                (IHelpContext) null, mcreator, "On kinetic tick",
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate/speed:number"));

        onKineticLazyTick = new ProcedureSelector(
                (IHelpContext) null, mcreator, "On kinetic lazy tick",
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate/speed:number"));

        onGoggleTooltip = new ProcedureSelector(
                (IHelpContext) null, mcreator, "On goggle tooltip",
                AbstractProcedureSelector.Side.CLIENT,
                Dependency.fromString("x:number/y:number/z:number/world:world/entity:entity/blockstate:blockstate"));

        onRedstoneLinkReceive = new ProcedureSelector(
                (IHelpContext) null, mcreator, "On redstone link receive",
                Dependency.fromString("x:number/y:number/z:number/world:world/blockstate:blockstate/signal:number"));

        // ── Validation ───────────────────────────────────────────────────────
        texture = new TextureSelectionButton(new TypedTextureSelectorDialog(mcreator, TextureType.BLOCK)).setFlipUV(true);
        textureTop = new TextureSelectionButton(new TypedTextureSelectorDialog(mcreator, TextureType.BLOCK)).setFlipUV(true);
        textureLeft = new TextureSelectionButton(new TypedTextureSelectorDialog(mcreator, TextureType.BLOCK));
        textureFront = new TextureSelectionButton(new TypedTextureSelectorDialog(mcreator, TextureType.BLOCK));
        textureRight = new TextureSelectionButton(new TypedTextureSelectorDialog(mcreator, TextureType.BLOCK));
        textureBack = new TextureSelectionButton(new TypedTextureSelectorDialog(mcreator, TextureType.BLOCK));
        itemTexture = new TextureSelectionButton(new TypedTextureSelectorDialog(mcreator, TextureType.ITEM), 32);

        texture.setValidator(new TileHolderValidator(texture));
        page1group.addValidationElement(texture);

        name.setValidator(new TextFieldValidator(name, "Block name cannot be empty"));
        name.enableRealtimeValidation();
        page2group.addValidationElement(name);

        // ── Build pages ──────────────────────────────────────────────────────
        if (!isEditingMode()) {
            boundingBoxList.setEntries(Collections.singletonList(new IBlockWithBoundingBox.BoxEntry()));
        }

        addPage(L10N.t("elementgui.common.page_visual"), buildVisualPage());
        addPage(L10N.t("elementgui.common.page_properties"), buildPropertiesPage());
        addPage("Create Kinetics", buildKineticsPage());
        addPage("Shafts", buildShaftsPage());
        addPage("Cogs", buildCogsPage());
        addPage("Visual Boxes", buildVisualBoxesPage());
        addPage("Rotating Visuals", buildRotatingVisualsPage());
        addPage(L10N.t("elementgui.common.page_triggers"), buildEventsPage());
        addPage("Redstone && Links", buildRedstonePage());
        addPage(L10N.t("elementgui.block.page_tile_entity"), buildAdvancedPage());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Page builders
    // ─────────────────────────────────────────────────────────────────────────

    private JPanel buildVisualPage() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setOpaque(false);

        // Texture cross arrangement (matches vanilla block GUI style)
        JPanel destal = new JPanel(new GridLayout(3, 4));
        destal.setOpaque(false);
        destal.add(new JLabel());
        destal.add(ComponentUtils.squareAndBorder(textureTop, L10N.t("elementgui.block.texture_place_top")));
        destal.add(new JLabel()); destal.add(new JLabel());
        destal.add(ComponentUtils.squareAndBorder(textureLeft, new Color(126, 196, 255), L10N.t("elementgui.block.texture_place_left_overlay")));
        destal.add(ComponentUtils.squareAndBorder(textureFront, L10N.t("elementgui.block.texture_place_front_side")));
        destal.add(ComponentUtils.squareAndBorder(textureRight, L10N.t("elementgui.block.texture_place_right")));
        destal.add(ComponentUtils.squareAndBorder(textureBack, L10N.t("elementgui.block.texture_place_back")));
        destal.add(new JLabel());
        destal.add(ComponentUtils.squareAndBorder(texture, new Color(125, 255, 174), L10N.t("elementgui.block.texture_place_bottom_main")));
        destal.add(new JLabel()); destal.add(new JLabel());

        // Propagate left texture to all faces on first select
        textureLeft.addTextureSelectedListener(event -> {
            if (!texture.hasTexture() && !textureTop.hasTexture() && !textureBack.hasTexture()
                    && !textureFront.hasTexture() && !textureRight.hasTexture()) {
                texture.setTexture(textureLeft.getTextureHolder());
                textureTop.setTexture(textureLeft.getTextureHolder());
                textureBack.setTexture(textureLeft.getTextureHolder());
                textureFront.setTexture(textureLeft.getTextureHolder());
                textureRight.setTexture(textureLeft.getTextureHolder());
            }
        });

        JPanel texBorder = new JPanel(new BorderLayout());
        texBorder.setOpaque(false);
        texBorder.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder((Color) javax.swing.UIManager.get("MCreatorLAF.BRIGHT_COLOR"), 1),
                L10N.t("elementgui.block.block_textures"), 0, 0, getFont().deriveFont(12f),
                (Color) javax.swing.UIManager.get("MCreatorLAF.BRIGHT_COLOR")));
        texBorder.add(PanelUtils.totalCenterInPanel(destal));

        // Item texture
        JPanel itemPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        itemPanel.setOpaque(false);
        itemPanel.add(new JLabel("Item texture:"));
        itemPanel.add(itemTexture);

        // Render settings grid
        JPanel renderGrid = new JPanel(new GridLayout(5, 2, 0, 2));
        renderGrid.setOpaque(false);
        renderGrid.add(L10N.label("elementgui.block.has_trasparency")); renderGrid.add(hasTransparency);
        renderGrid.add(L10N.label("elementgui.block.transparency_type")); renderGrid.add(transparencyType);
        renderGrid.add(L10N.label("elementgui.block.rotation_mode")); renderGrid.add(rotationMode);
        renderGrid.add(L10N.label("elementgui.common.emissive_rendering")); renderGrid.add(emissiveRendering);
        renderGrid.add(itemPanel); renderGrid.add(new JLabel());

        hasTransparency.setOpaque(false);
        emissiveRendering.setOpaque(false);

        panel.add(texBorder, BorderLayout.CENTER);
        panel.add(PanelUtils.pullElementUp(renderGrid), BorderLayout.EAST);
        return panel;
    }

    private JPanel buildPropertiesPage() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setOpaque(false);

        // Main properties grid (2-column label+field)
        JPanel selp = new JPanel(new GridLayout(0, 2, 0, 2));
        selp.setOpaque(false);
        ComponentUtils.deriveFont(name, 16f);

        selp.add(L10N.label("elementgui.common.name_in_gui")); selp.add(name);
        selp.add(L10N.label("elementgui.common.creative_tabs")); selp.add(creativeTabs);
        selp.add(L10N.label("elementgui.common.hardness")); selp.add(hardness);
        selp.add(L10N.label("elementgui.common.resistance")); selp.add(resistance);
        selp.add(L10N.label("elementgui.common.luminance")); selp.add(luminance);
        selp.add(L10N.label("elementgui.common.light_opacity")); selp.add(lightOpacity);
        selp.add(L10N.label("elementgui.block.has_gravity")); selp.add(hasGravity);
        selp.add(L10N.label("elementgui.block.is_waterloggable")); selp.add(isWaterloggable);
        selp.add(L10N.label("elementgui.block.is_unbreakable")); selp.add(unbreakable);
        selp.add(L10N.label("elementgui.block.is_replaceable")); selp.add(isReplaceable);
        selp.add(L10N.label("elementgui.block.harvest_tool")); selp.add(destroyTool);
        selp.add(L10N.label("elementgui.block.vanilla_tool_tier")); selp.add(vanillaToolTier);
        selp.add(L10N.label("elementgui.block.requires_correct_tool")); selp.add(requiresCorrectTool);
        selp.add(L10N.label("elementgui.common.custom_drop")); selp.add(PanelUtils.centerInPanel(customDrop));
        selp.add(L10N.label("elementgui.common.drop_amount")); selp.add(dropAmount);
        selp.add(L10N.label("elementgui.common.use_loot_table_for_drop")); selp.add(PanelUtils.centerInPanel(useLootTableForDrops));

        hasGravity.setOpaque(false); isWaterloggable.setOpaque(false);
        unbreakable.setOpaque(false); isReplaceable.setOpaque(false);
        requiresCorrectTool.setOpaque(false); useLootTableForDrops.setOpaque(false);

        useLootTableForDrops.addActionListener(e -> {
            customDrop.setEnabled(!useLootTableForDrops.isSelected());
            dropAmount.setEnabled(!useLootTableForDrops.isSelected());
        });

        // Bounding boxes
        JPanel bbPanel = new JPanel(new BorderLayout());
        bbPanel.setOpaque(false);
        bbPanel.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder((Color) javax.swing.UIManager.get("MCreatorLAF.BRIGHT_COLOR"), 1),
                L10N.t("elementgui.common.page_bounding_boxes"), 0, 0, getFont().deriveFont(12f),
                (Color) javax.swing.UIManager.get("MCreatorLAF.BRIGHT_COLOR")));
        bbPanel.add(boundingBoxList, BorderLayout.CENTER);

        panel.add(PanelUtils.pullElementUp(selp), BorderLayout.WEST);
        panel.add(bbPanel, BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildKineticsPage() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setOpaque(false);

        JPanel form = new JPanel(new GridBagLayout());
        form.setOpaque(false);
        GridBagConstraints gbc = gbc();

        // Role and facing
        JPanel rolePanel = titledPanel("Create Kinetic Role & Orientation");
        JPanel roleGrid = new JPanel(new GridLayout(4, 2, 0, 4));
        roleGrid.setOpaque(false);
        roleGrid.add(new JLabel("Kinetic role:")); roleGrid.add(kineticRole);
        roleGrid.add(new JLabel("Facing type:")); roleGrid.add(createFacingType);
        roleGrid.add(enableKineticTick); roleGrid.add(new JLabel());
        roleGrid.add(enableGoggles); roleGrid.add(new JLabel());
        rolePanel.add(roleGrid);
        addFull(form, gbc, rolePanel);

        // Consumer: Stress Impact
        JPanel stressPanel = titledPanel("Consumer: Stress Impact (SU consumed)");
        JPanel stressGrid = new JPanel(new GridLayout(2, 2, 0, 4));
        stressGrid.setOpaque(false);
        stressGrid.add(new JLabel("Default impact (SU):")); stressGrid.add(defaultStressImpact);
        stressGrid.add(new JLabel("Procedure (returns SU):")); stressGrid.add(stressImpactProcedure);
        stressPanel.add(stressGrid);
        addFull(form, gbc, stressPanel);

        // Generator: Stress Capacity
        JPanel capPanel = titledPanel("Generator: Stress Capacity (SU budget)");
        JPanel capGrid = new JPanel(new GridLayout(2, 2, 0, 4));
        capGrid.setOpaque(false);
        capGrid.add(new JLabel("Default capacity (SU):")); capGrid.add(defaultCapacity);
        capGrid.add(new JLabel("Procedure (returns SU):")); capGrid.add(capacityProcedure);
        capPanel.add(capGrid);
        addFull(form, gbc, capPanel);

        // Generator: Speed
        JPanel speedPanel = titledPanel("Generator: Generated Speed (RPM)");
        JPanel speedGrid = new JPanel(new GridLayout(2, 2, 0, 4));
        speedGrid.setOpaque(false);
        speedGrid.add(new JLabel("Default speed (RPM):")); speedGrid.add(defaultGeneratedSpeed);
        speedGrid.add(new JLabel("Procedure (returns RPM):")); speedGrid.add(generatedSpeedProcedure);
        speedPanel.add(speedGrid);
        addFull(form, gbc, speedPanel);

        JScrollPane scroll = new JScrollPane(form);
        scroll.setOpaque(false); scroll.getViewport().setOpaque(false); scroll.setBorder(null);
        panel.add(scroll, BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildShaftsPage() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        panel.setOpaque(false);
        JLabel info = ComponentUtils.deriveFont(new JLabel(
                "<html><b>Shaft Connections</b> — Add independent shaft connections on any face of this block.<br>"
                + "INPUT: consumes rotation &nbsp;·&nbsp; OUTPUT: provides rotation &nbsp;·&nbsp; BOTH: bidirectional.<br>"
                + "Enable 'Independent' for shafts not connected to the block's main kinetic network.</html>"), 11f);
        info.setBorder(BorderFactory.createEmptyBorder(6, 8, 6, 8));
        panel.add(info, BorderLayout.NORTH);
        panel.add(new JScrollPane(shaftList), BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildCogsPage() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        panel.setOpaque(false);
        JLabel info = ComponentUtils.deriveFont(new JLabel(
                "<html><b>Cog / Gear Connections</b> — Define gear-like mesh points on this block.<br>"
                + "SMALL: 1:1 gear ratio &nbsp;·&nbsp; LARGE: 1:2 gear ratio &nbsp;·&nbsp; Axis: rotation direction.</html>"), 11f);
        info.setBorder(BorderFactory.createEmptyBorder(6, 8, 6, 8));
        panel.add(info, BorderLayout.NORTH);
        panel.add(new JScrollPane(cogList), BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildVisualBoxesPage() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        panel.setOpaque(false);
        JLabel info = ComponentUtils.deriveFont(new JLabel(
                "<html><b>Scroll Value / Visual Boxes</b> — Floating UI boxes rendered above the block (Create scroll-value system).<br>"
                + "NUMERIC: number range &nbsp;·&nbsp; OPTIONS: cycling text mode &nbsp;·&nbsp; ICON_OPTIONS: icon+text selector.</html>"), 11f);
        info.setBorder(BorderFactory.createEmptyBorder(6, 8, 6, 8));
        panel.add(info, BorderLayout.NORTH);
        panel.add(new JScrollPane(visualBoxList), BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildRotatingVisualsPage() {
        JPanel panel = new JPanel(new BorderLayout(5, 5));
        panel.setOpaque(false);
        JLabel info = ComponentUtils.deriveFont(new JLabel(
                "<html><b>Rotating Visual Parts</b> — Spinning model parts rendered via Create's KineticBlockEntityRenderer.<br>"
                + "Speed multiplier is relative to the block's own kinetic RPM. Offset positions part from block center.</html>"), 11f);
        info.setBorder(BorderFactory.createEmptyBorder(6, 8, 6, 8));
        panel.add(info, BorderLayout.NORTH);
        panel.add(new JScrollPane(rotatingVisualList), BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildEventsPage() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setOpaque(false);

        JPanel inner = new JPanel();
        inner.setLayout(new BoxLayout(inner, BoxLayout.PAGE_AXIS));
        inner.setOpaque(false);

        // Create events
        JPanel createEv = titledPanel("Create Kinetic Events");
        JPanel cGrid = new JPanel(new GridLayout(0, 2, 0, 4));
        cGrid.setOpaque(false);
        cGrid.add(new JLabel("On kinetic tick:")); cGrid.add(onKineticTick);
        cGrid.add(new JLabel("On kinetic lazy tick:")); cGrid.add(onKineticLazyTick);
        cGrid.add(new JLabel("On goggle tooltip:")); cGrid.add(onGoggleTooltip);
        createEv.add(cGrid);
        inner.add(createEv);
        inner.add(Box.createVerticalStrut(4));

        // Standard block events
        JPanel stdEv = titledPanel("Standard Block Events");
        JPanel sGrid = new JPanel(new GridLayout(0, 2, 0, 4));
        sGrid.setOpaque(false);
        sGrid.add(new JLabel(L10N.t("elementgui.block.event_on_block_added"))); sGrid.add(onBlockAdded);
        sGrid.add(new JLabel(L10N.t("elementgui.common.event_on_neighbour_block_changes"))); sGrid.add(onNeighbourBlockChanges);
        sGrid.add(new JLabel(L10N.t("elementgui.common.event_on_update_tick"))); sGrid.add(onTickUpdate);
        sGrid.add(new JLabel(L10N.t("elementgui.block.event_on_block_destroyed_by_player"))); sGrid.add(onDestroyedByPlayer);
        sGrid.add(new JLabel(L10N.t("elementgui.block.event_on_block_destroyed_by_explosion"))); sGrid.add(onDestroyedByExplosion);
        sGrid.add(new JLabel(L10N.t("elementgui.block.event_on_entity_collides"))); sGrid.add(onEntityCollides);
        sGrid.add(new JLabel(L10N.t("elementgui.block.event_on_entity_walks_on"))); sGrid.add(onEntityWalksOn);
        sGrid.add(new JLabel(L10N.t("elementgui.block.event_on_right_clicked"))); sGrid.add(onRightClicked);
        stdEv.add(sGrid);
        inner.add(stdEv);

        JScrollPane scroll = new JScrollPane(inner);
        scroll.setOpaque(false); scroll.getViewport().setOpaque(false); scroll.setBorder(null);
        panel.add(scroll, BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildRedstonePage() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setOpaque(false);

        JPanel inner = new JPanel();
        inner.setLayout(new BoxLayout(inner, BoxLayout.PAGE_AXIS));
        inner.setOpaque(false);

        // Standard redstone
        JPanel stdRed = titledPanel("Standard Redstone");
        JPanel stdGrid = new JPanel(new GridLayout(0, 2, 0, 4));
        stdGrid.setOpaque(false);
        canProvidePower.setOpaque(false);
        stdGrid.add(L10N.label("elementgui.block.emits_redstone")); stdGrid.add(canProvidePower);
        stdGrid.add(new JLabel("Emitted power (0-15):")); stdGrid.add(emittedRedstonePower);
        stdGrid.add(new JLabel(L10N.t("elementgui.block.event_on_redstone_on"))); stdGrid.add(onRedstoneOn);
        stdGrid.add(new JLabel(L10N.t("elementgui.block.event_on_redstone_off"))); stdGrid.add(onRedstoneOff);
        canProvidePower.addActionListener(e -> emittedRedstonePower.setEnabled(canProvidePower.isSelected()));
        emittedRedstonePower.setEnabled(false);
        stdRed.add(stdGrid);
        inner.add(stdRed);
        inner.add(Box.createVerticalStrut(4));

        // Create Redstone Link
        JPanel linkRed = titledPanel("Create Redstone Link");
        JPanel linkGrid = new JPanel(new GridLayout(0, 2, 0, 4));
        linkGrid.setOpaque(false);
        enableRedstoneLink.setOpaque(false);
        linkGrid.add(new JLabel("Enable redstone link:")); linkGrid.add(enableRedstoneLink);
        linkGrid.add(new JLabel("Link behavior:")); linkGrid.add(redstoneLinkBehavior);
        linkGrid.add(new JLabel("On link receive:")); linkGrid.add(onRedstoneLinkReceive);
        linkGrid.add(new JLabel("Link output signal:")); linkGrid.add(redstoneLinkOutputProcedure);
        linkRed.add(linkGrid);
        inner.add(linkRed);

        JScrollPane scroll = new JScrollPane(inner);
        scroll.setOpaque(false); scroll.getViewport().setOpaque(false); scroll.setBorder(null);
        panel.add(scroll, BorderLayout.CENTER);
        return panel;
    }

    private JPanel buildAdvancedPage() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setOpaque(false);

        JPanel inner = new JPanel();
        inner.setLayout(new BoxLayout(inner, BoxLayout.PAGE_AXIS));
        inner.setOpaque(false);

        // Inventory
        JPanel invPanel = titledPanel("Block Entity / Inventory");
        JPanel invGrid = new JPanel(new GridLayout(0, 2, 0, 4));
        invGrid.setOpaque(false);
        hasInventory.setOpaque(false); inventoryDropWhenDestroyed.setOpaque(false);
        invGrid.add(L10N.label("elementgui.block.has_inventory")); invGrid.add(hasInventory);
        invGrid.add(new JLabel("Inventory size:")); invGrid.add(inventorySize);
        invGrid.add(new JLabel("Max stack size:")); invGrid.add(inventoryStackSize);
        invGrid.add(new JLabel("Drop when destroyed:")); invGrid.add(inventoryDropWhenDestroyed);
        hasInventory.addActionListener(e -> refreshInventoryFields());
        refreshInventoryFields();
        invPanel.add(invGrid);
        inner.add(invPanel);
        inner.add(Box.createVerticalStrut(4));

        // Forge Energy
        JPanel fePanel = titledPanel("Forge Energy Storage (FE)");
        JPanel feGrid = new JPanel(new GridLayout(0, 2, 0, 4));
        feGrid.setOpaque(false);
        hasEnergyStorage.setOpaque(false);
        feGrid.add(L10N.label("elementgui.block.enable_energy_storage")); feGrid.add(hasEnergyStorage);
        feGrid.add(new JLabel("Initial stored FE:")); feGrid.add(energyInitial);
        feGrid.add(new JLabel("Capacity (FE):")); feGrid.add(energyCapacity);
        feGrid.add(new JLabel("Max receive (FE/t):")); feGrid.add(energyMaxReceive);
        feGrid.add(new JLabel("Max extract (FE/t):")); feGrid.add(energyMaxExtract);
        fePanel.add(feGrid);
        inner.add(fePanel);

        JScrollPane scroll = new JScrollPane(inner);
        scroll.setOpaque(false); scroll.getViewport().setOpaque(false); scroll.setBorder(null);
        panel.add(scroll, BorderLayout.CENTER);
        return panel;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Data binding: openInEditingMode (Element → GUI)
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    public void openInEditingMode(CreateBlock element) {
        // Visual tab
        if (element.texture != null) texture.setTexture(element.texture);
        if (element.textureTop != null) textureTop.setTexture(element.textureTop);
        if (element.textureLeft != null) textureLeft.setTexture(element.textureLeft);
        if (element.textureFront != null) textureFront.setTexture(element.textureFront);
        if (element.textureRight != null) textureRight.setTexture(element.textureRight);
        if (element.textureBack != null) textureBack.setTexture(element.textureBack);
        if (element.itemTexture != null) itemTexture.setTexture(element.itemTexture);
        hasTransparency.setSelected(element.hasTransparency);
        transparencyType.setSelectedItem(element.transparencyType);
        rotationMode.setSelectedIndex(element.rotationMode);
        emissiveRendering.setSelected(element.emissiveRendering);

        // Properties tab
        name.setText(element.name);
        hardness.setValue(element.hardness);
        resistance.setValue(element.resistance);
        luminance.setSelectedProcedure(element.luminance);
        lightOpacity.setValue(element.lightOpacity);
        hasGravity.setSelected(element.hasGravity);
        isWaterloggable.setSelected(element.isWaterloggable);
        unbreakable.setSelected(element.unbreakable);
        isReplaceable.setSelected(element.isReplaceable);
        destroyTool.setSelectedItem(element.destroyTool);
        vanillaToolTier.setSelectedItem(element.vanillaToolTier);
        requiresCorrectTool.setSelected(element.requiresCorrectTool);
        if (element.creativeTabs != null) creativeTabs.setListElements(element.creativeTabs);
        if (element.boundingBoxes != null) boundingBoxList.setEntries(element.boundingBoxes);
        customDrop.setBlock(element.customDrop);
        dropAmount.setValue(element.dropAmount);
        useLootTableForDrops.setSelected(element.useLootTableForDrops);
        canProvidePower.setSelected(element.canProvidePower);
        emittedRedstonePower.setSelectedProcedure(element.emittedRedstonePower);
        emittedRedstonePower.setEnabled(element.canProvidePower);

        // Kinetics tab
        kineticRole.setSelectedItem(element.kineticRole);
        createFacingType.setSelectedItem(element.createFacingType);
        defaultStressImpact.setValue(element.defaultStressImpact);
        stressImpactProcedure.setSelectedProcedure(element.stressImpactProcedure);
        defaultCapacity.setValue(element.defaultCapacity);
        capacityProcedure.setSelectedProcedure(element.capacityProcedure);
        defaultGeneratedSpeed.setValue(element.defaultGeneratedSpeed);
        generatedSpeedProcedure.setSelectedProcedure(element.generatedSpeedProcedure);
        enableKineticTick.setSelected(element.enableKineticTick);
        enableGoggles.setSelected(element.enableGoggles);

        // List editors
        if (element.shafts != null) shaftList.setEntries(element.shafts);
        if (element.cogs != null) cogList.setEntries(element.cogs);
        if (element.visualBoxes != null) visualBoxList.setEntries(element.visualBoxes);
        if (element.rotatingVisuals != null) rotatingVisualList.setEntries(element.rotatingVisuals);

        // Events tab
        onKineticTick.setSelectedProcedure(element.onKineticTick);
        onKineticLazyTick.setSelectedProcedure(element.onKineticLazyTick);
        onGoggleTooltip.setSelectedProcedure(element.onGoggleTooltip);
        onBlockAdded.setSelectedProcedure(element.onBlockAdded);
        onNeighbourBlockChanges.setSelectedProcedure(element.onNeighbourBlockChanges);
        onTickUpdate.setSelectedProcedure(element.onTickUpdate);
        onDestroyedByPlayer.setSelectedProcedure(element.onDestroyedByPlayer);
        onDestroyedByExplosion.setSelectedProcedure(element.onDestroyedByExplosion);
        onEntityCollides.setSelectedProcedure(element.onEntityCollides);
        onEntityWalksOn.setSelectedProcedure(element.onEntityWalksOn);
        onRightClicked.setSelectedProcedure(element.onRightClicked);

        // Redstone tab
        onRedstoneOn.setSelectedProcedure(element.onRedstoneOn);
        onRedstoneOff.setSelectedProcedure(element.onRedstoneOff);
        enableRedstoneLink.setSelected(element.enableRedstoneLink);
        redstoneLinkBehavior.setSelectedItem(element.redstoneLinkBehavior);
        onRedstoneLinkReceive.setSelectedProcedure(element.onRedstoneLinkReceive);
        redstoneLinkOutputProcedure.setSelectedProcedure(element.redstoneLinkOutputProcedure);

        // Advanced tab
        hasInventory.setSelected(element.hasInventory);
        inventorySize.setValue(element.inventorySize);
        inventoryStackSize.setValue(element.inventoryStackSize);
        inventoryDropWhenDestroyed.setSelected(element.inventoryDropWhenDestroyed);
        hasEnergyStorage.setSelected(element.hasEnergyStorage);
        energyInitial.setValue(element.energyInitial);
        energyCapacity.setValue(element.energyCapacity);
        energyMaxReceive.setValue(element.energyMaxReceive);
        energyMaxExtract.setValue(element.energyMaxExtract);
        refreshInventoryFields();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Data binding: getElementFromGUI (GUI → Element)
    // ─────────────────────────────────────────────────────────────────────────
    @Override
    public CreateBlock getElementFromGUI() {
        CreateBlock element = new CreateBlock(modElement);

        // Visual
        element.texture = texture.getTextureHolder();
        element.textureTop = textureTop.getTextureHolder();
        element.textureLeft = textureLeft.getTextureHolder();
        element.textureFront = textureFront.getTextureHolder();
        element.textureRight = textureRight.getTextureHolder();
        element.textureBack = textureBack.getTextureHolder();
        element.itemTexture = itemTexture.getTextureHolder();
        element.hasTransparency = hasTransparency.isSelected();
        element.transparencyType = (String) transparencyType.getSelectedItem();
        element.rotationMode = rotationMode.getSelectedIndex();
        element.emissiveRendering = emissiveRendering.isSelected();

        // Properties
        element.name = name.getText();
        element.hardness = (Double) hardness.getValue();
        element.resistance = (Double) resistance.getValue();
        element.luminance = luminance.getSelectedProcedure();
        element.lightOpacity = (Integer) lightOpacity.getValue();
        element.hasGravity = hasGravity.isSelected();
        element.isWaterloggable = isWaterloggable.isSelected();
        element.unbreakable = unbreakable.isSelected();
        element.isReplaceable = isReplaceable.isSelected();
        element.destroyTool = (String) destroyTool.getSelectedItem();
        element.vanillaToolTier = (String) vanillaToolTier.getSelectedItem();
        element.requiresCorrectTool = requiresCorrectTool.isSelected();
        element.creativeTabs = creativeTabs.getListElements();
        element.boundingBoxes = boundingBoxList.getEntries();
        element.customDrop = customDrop.getBlock();
        element.dropAmount = (Integer) dropAmount.getValue();
        element.useLootTableForDrops = useLootTableForDrops.isSelected();
        element.canProvidePower = canProvidePower.isSelected();
        element.emittedRedstonePower = emittedRedstonePower.getSelectedProcedure();

        // Kinetics
        element.kineticRole = (String) kineticRole.getSelectedItem();
        element.createFacingType = (String) createFacingType.getSelectedItem();
        element.defaultStressImpact = (Double) defaultStressImpact.getValue();
        element.stressImpactProcedure = stressImpactProcedure.getSelectedProcedure();
        element.defaultCapacity = (Double) defaultCapacity.getValue();
        element.capacityProcedure = capacityProcedure.getSelectedProcedure();
        element.defaultGeneratedSpeed = (Double) defaultGeneratedSpeed.getValue();
        element.generatedSpeedProcedure = generatedSpeedProcedure.getSelectedProcedure();
        element.enableKineticTick = enableKineticTick.isSelected();
        element.enableGoggles = enableGoggles.isSelected();

        // Lists
        element.shafts = shaftList.getEntries();
        element.cogs = cogList.getEntries();
        element.visualBoxes = visualBoxList.getEntries();
        element.rotatingVisuals = rotatingVisualList.getEntries();

        // Events
        element.onKineticTick = onKineticTick.getSelectedProcedure();
        element.onKineticLazyTick = onKineticLazyTick.getSelectedProcedure();
        element.onGoggleTooltip = onGoggleTooltip.getSelectedProcedure();
        element.onBlockAdded = onBlockAdded.getSelectedProcedure();
        element.onNeighbourBlockChanges = onNeighbourBlockChanges.getSelectedProcedure();
        element.onTickUpdate = onTickUpdate.getSelectedProcedure();
        element.onDestroyedByPlayer = onDestroyedByPlayer.getSelectedProcedure();
        element.onDestroyedByExplosion = onDestroyedByExplosion.getSelectedProcedure();
        element.onEntityCollides = onEntityCollides.getSelectedProcedure();
        element.onEntityWalksOn = onEntityWalksOn.getSelectedProcedure();
        element.onRightClicked = onRightClicked.getSelectedProcedure();

        // Redstone
        element.onRedstoneOn = onRedstoneOn.getSelectedProcedure();
        element.onRedstoneOff = onRedstoneOff.getSelectedProcedure();
        element.enableRedstoneLink = enableRedstoneLink.isSelected();
        element.redstoneLinkBehavior = (String) redstoneLinkBehavior.getSelectedItem();
        element.onRedstoneLinkReceive = onRedstoneLinkReceive.getSelectedProcedure();
        element.redstoneLinkOutputProcedure = redstoneLinkOutputProcedure.getSelectedProcedure();

        // Advanced
        element.hasInventory = hasInventory.isSelected();
        element.inventorySize = (Integer) inventorySize.getValue();
        element.inventoryStackSize = (Integer) inventoryStackSize.getValue();
        element.inventoryDropWhenDestroyed = inventoryDropWhenDestroyed.isSelected();
        element.hasEnergyStorage = hasEnergyStorage.isSelected();
        element.energyInitial = (Integer) energyInitial.getValue();
        element.energyCapacity = (Integer) energyCapacity.getValue();
        element.energyMaxReceive = (Integer) energyMaxReceive.getValue();
        element.energyMaxExtract = (Integer) energyMaxExtract.getValue();

        return element;
    }

    @Override
    public @Nonnull List<AggregatedValidationResult> getValidationResults() {
        return Arrays.asList(
                new AggregatedValidationResult(page1group),
                new AggregatedValidationResult(page2group));
    }

    @Override
    public void reloadDataLists() {
        super.reloadDataLists();
        luminance.refreshListKeepSelected();
        onKineticTick.refreshListKeepSelected();
        onKineticLazyTick.refreshListKeepSelected();
        onGoggleTooltip.refreshListKeepSelected();
        onBlockAdded.refreshListKeepSelected();
        onNeighbourBlockChanges.refreshListKeepSelected();
        onTickUpdate.refreshListKeepSelected();
        onDestroyedByPlayer.refreshListKeepSelected();
        onDestroyedByExplosion.refreshListKeepSelected();
        onEntityCollides.refreshListKeepSelected();
        onEntityWalksOn.refreshListKeepSelected();
        onRightClicked.refreshListKeepSelected();
        onRedstoneOn.refreshListKeepSelected();
        onRedstoneOff.refreshListKeepSelected();
        onRedstoneLinkReceive.refreshListKeepSelected();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────────────────

    private void refreshInventoryFields() {
        boolean en = hasInventory.isSelected();
        inventorySize.setEnabled(en);
        inventoryStackSize.setEnabled(en);
        inventoryDropWhenDestroyed.setEnabled(en);
    }

    private static GridBagConstraints gbc() {
        GridBagConstraints c = new GridBagConstraints();
        c.fill = GridBagConstraints.HORIZONTAL;
        c.anchor = GridBagConstraints.NORTHWEST;
        c.insets = new Insets(3, 4, 3, 4);
        c.gridx = 0; c.gridy = 0;
        c.weightx = 1; c.weighty = 0;
        c.gridwidth = 1;
        return c;
    }

    private static void addFull(JPanel panel, GridBagConstraints gbc, JComponent comp) {
        gbc.gridwidth = GridBagConstraints.REMAINDER;
        gbc.weightx = 1;
        panel.add(comp, gbc);
        gbc.gridy++;
    }

    private JPanel titledPanel(String title) {
        JPanel p = new JPanel(new BorderLayout());
        p.setOpaque(false);
        p.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder((Color) javax.swing.UIManager.get("MCreatorLAF.BRIGHT_COLOR"), 1),
                title, TitledBorder.LEADING, TitledBorder.DEFAULT_POSITION,
                getFont().deriveFont(Font.BOLD, 11f),
                (Color) javax.swing.UIManager.get("MCreatorLAF.BRIGHT_COLOR")));
        return p;
    }
}
